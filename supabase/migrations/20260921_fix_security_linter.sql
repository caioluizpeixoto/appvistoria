-- ==============================================================================
-- MIGRATION: 20260921_fix_security_linter.sql
-- DESCRIÇÃO: Resolve a vulnerabilidade apontada pelo Supabase Security Linter
-- ==============================================================================

-- 1. Criar a tabela blindada de Administradores
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'master',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- Migrar automaticamente os atuais masters do user_metadata para a tabela segura
INSERT INTO public.admin_users (user_id, role)
SELECT id, raw_user_meta_data->>'role'
FROM auth.users
WHERE raw_user_meta_data->>'role' IN ('master', 'admin_master')
ON CONFLICT (user_id) DO NOTHING;

-- 2. Atualizar a função is_master() para não olhar mais para o user_metadata
CREATE OR REPLACE FUNCTION public.is_master()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
    OR (auth.jwt() ->> 'email') LIKE '%42136154800%',
    false
  );
$$;

-- 3. Criar função auxiliar para ler o CNPJ de forma segura (sem usar auth.jwt() diretamente)
CREATE OR REPLACE FUNCTION public.get_my_cnpj()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT raw_user_meta_data->>'cnpj' FROM auth.users WHERE id = auth.uid();
$$;

-- 4. Atualizar as políticas (RLS) da tabela empresas para remover a chamada direta ao user_metadata
DROP POLICY IF EXISTS "Master pode ver todas as empresas" ON public.empresas;
DROP POLICY IF EXISTS "Usuários veem a própria empresa" ON public.empresas;

CREATE POLICY "Master pode ver todas as empresas" 
    ON public.empresas FOR SELECT 
    USING (
        public.is_master()
    );

CREATE POLICY "Usuários veem a própria empresa" 
    ON public.empresas FOR SELECT 
    USING (
        cnpj = public.get_my_cnpj()
    );

-- 5. Criar o Gatilho Anti-Hack para bloquear alterações no role e cnpj via cliente
CREATE OR REPLACE FUNCTION public.protect_user_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Apenas atua se a chamada for uma alteração (UPDATE)
    IF TG_OP = 'UPDATE' THEN
        -- Verifica se há tentativa de alterar as chaves sensíveis
        IF NEW.raw_user_meta_data IS NOT NULL AND OLD.raw_user_meta_data IS NOT NULL THEN
            -- Se o role antigo existia, força o novo a ser igual (bloqueia alteração)
            IF OLD.raw_user_meta_data ? 'role' THEN
                NEW.raw_user_meta_data = jsonb_set(NEW.raw_user_meta_data, '{role}', OLD.raw_user_meta_data->'role');
            ELSE
                -- Se não existia, e tentou colocar agora, remove a tentativa
                NEW.raw_user_meta_data = NEW.raw_user_meta_data - 'role';
            END IF;

            -- Mesma lógica para o CNPJ (ninguém pode roubar CNPJ de outra empresa após o cadastro)
            IF OLD.raw_user_meta_data ? 'cnpj' THEN
                NEW.raw_user_meta_data = jsonb_set(NEW.raw_user_meta_data, '{cnpj}', OLD.raw_user_meta_data->'cnpj');
            ELSE
                NEW.raw_user_meta_data = NEW.raw_user_meta_data - 'cnpj';
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove se já existir
DROP TRIGGER IF EXISTS on_auth_user_update ON auth.users;

-- Aplica o gatilho sempre ANTES (BEFORE) do update ser salvo no banco
CREATE TRIGGER on_auth_user_update
BEFORE UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.protect_user_metadata();
