-- ==============================================================================
-- CORREÇÃO DE RLS: Master não estava conseguindo ler a tabela empresas
-- ==============================================================================

-- Remover a política antiga que estava com o caminho do JWT errado
DROP POLICY IF EXISTS "Master pode ver todas as empresas" ON public.empresas;
DROP POLICY IF EXISTS "Usuários veem a própria empresa" ON public.empresas;

-- Criar a política correta verificando os metadados do JWT iguais ao Flutter
CREATE POLICY "Master pode ver todas as empresas" 
    ON public.empresas FOR SELECT 
    USING (
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('master', 'admin_master')
        OR 
        (auth.jwt() ->> 'email') LIKE '%42136154800%'
    );

-- Criar a política para usuários normais verem apenas suas próprias empresas
CREATE POLICY "Usuários veem a própria empresa" 
    ON public.empresas FOR SELECT 
    USING (
        cnpj = (auth.jwt() -> 'user_metadata' ->> 'cnpj')
    );
