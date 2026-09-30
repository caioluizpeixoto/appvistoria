-- ==============================================================================
-- MIGRATION: Corrigir RLS de Empresas para extrair role do user_metadata
-- ==============================================================================

-- Permitir que o master crie empresas
DROP POLICY IF EXISTS "Master pode criar empresas" ON public.empresas;
CREATE POLICY "Master pode criar empresas"
    ON public.empresas FOR INSERT 
    WITH CHECK (
        (auth.jwt() -> 'user_metadata' ->> 'is_master')::boolean = true 
        OR 
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('master', 'admin_master')
    );

-- Permitir que o master atualize empresas
DROP POLICY IF EXISTS "Master pode atualizar empresas" ON public.empresas;
CREATE POLICY "Master pode atualizar empresas"
    ON public.empresas FOR UPDATE
    USING (
        (auth.jwt() -> 'user_metadata' ->> 'is_master')::boolean = true 
        OR 
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('master', 'admin_master')
    );
