-- ==============================================================================
-- MIGRATION: 20260914_admin_master_role.sql
-- DESCRIÇÃO: Implementação do Perfil Master (Admin Master) e Políticas de RLS
-- ==============================================================================

-- 1. ADICIONAR CAMPOS DE IDENTIFICAÇÃO DE EMPRESA NA TABELA vistorias_cloud
ALTER TABLE public.vistorias_cloud ADD COLUMN IF NOT EXISTS empresa_nome TEXT;
ALTER TABLE public.vistorias_cloud ADD COLUMN IF NOT EXISTS empresa_cnpj TEXT;

-- Índices de performance para busca e filtros do Master
CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_empresa_nome ON public.vistorias_cloud(empresa_nome);
CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_placa ON public.vistorias_cloud(placa);
CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_status ON public.vistorias_cloud(status);
CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_created_at ON public.vistorias_cloud(created_at DESC);

-- 2. FUNÇÃO AUXILIAR: is_master()
-- Verifica de forma segura se o usuário autenticado possui role 'master' ou 'admin_master'
CREATE OR REPLACE FUNCTION public.is_master()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('master', 'admin_master')
    OR (auth.jwt() ->> 'email') LIKE '%42136154800%',
    false
  );
$$;

-- 3. ATUALIZAR ROW LEVEL SECURITY (RLS) NA TABELA vistorias_cloud
-- Usuários comuns veem apenas seus próprios laudos; Master vê e controla todos.
DROP POLICY IF EXISTS "Usuários veem apenas suas próprias vistorias" ON public.vistorias_cloud;
DROP POLICY IF EXISTS "Vistorias visíveis pelo dono ou master" ON public.vistorias_cloud;

CREATE POLICY "Vistorias visíveis pelo dono ou master" 
    ON public.vistorias_cloud FOR ALL 
    USING (auth.uid() = user_id OR public.is_master()) 
    WITH CHECK (auth.uid() = user_id OR public.is_master());

-- 4. ATUALIZAR RLS NAS TABELAS clientes_cloud E vistoriadores_cloud
DROP POLICY IF EXISTS "Usuários veem apenas seus próprios clientes" ON public.clientes_cloud;
DROP POLICY IF EXISTS "Clientes visíveis pelo dono ou master" ON public.clientes_cloud;

CREATE POLICY "Clientes visíveis pelo dono ou master" 
    ON public.clientes_cloud FOR ALL 
    USING (auth.uid() = user_id OR public.is_master()) 
    WITH CHECK (auth.uid() = user_id OR public.is_master());

DROP POLICY IF EXISTS "Usuários veem apenas seus próprios vistoriadores" ON public.vistoriadores_cloud;
DROP POLICY IF EXISTS "Vistoriadores visíveis pelo dono ou master" ON public.vistoriadores_cloud;

CREATE POLICY "Vistoriadores visíveis pelo dono ou master" 
    ON public.vistoriadores_cloud FOR ALL 
    USING (auth.uid() = user_id OR public.is_master()) 
    WITH CHECK (auth.uid() = user_id OR public.is_master());

-- 5. POLÍTICAS DE STORAGE PARA LAUDOS E FOTOS (STORAGE BUCKETS)
-- Permitir que o Master visualize qualquer PDF e foto de vistoria
DROP POLICY IF EXISTS "Master pode ler todos os PDFs" ON storage.objects;
CREATE POLICY "Master pode ler todos os PDFs"
    ON storage.objects FOR SELECT
    USING (
      bucket_id = 'laudos-pdf' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_master())
    );

DROP POLICY IF EXISTS "Master pode ler todas as Fotos" ON storage.objects;
CREATE POLICY "Master pode ler todas as Fotos"
    ON storage.objects FOR SELECT
    USING (
      bucket_id = 'fotos-vistoria' AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_master())
    );

-- 6. RPC: Resumo de Empresas e Laudos para o Painel Master
CREATE OR REPLACE FUNCTION public.get_empresas_resumo_master()
RETURNS TABLE (
    user_id UUID,
    empresa_nome TEXT,
    total_vistorias BIGINT,
    ultima_vistoria TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_master() THEN
        RAISE EXCEPTION 'Acesso negado: apenas perfil master tem permissão para acessar esta função.';
    END IF;

    RETURN QUERY
    SELECT 
        v.user_id,
        COALESCE(NULLIF(v.empresa_nome, ''), 'Empresa ' || SUBSTRING(v.user_id::TEXT, 1, 8)) AS empresa_nome,
        COUNT(*)::BIGINT AS total_vistorias,
        MAX(v.created_at) AS ultima_vistoria
    FROM public.vistorias_cloud v
    GROUP BY v.user_id, v.empresa_nome
    ORDER BY total_vistorias DESC;
END;
$$;
