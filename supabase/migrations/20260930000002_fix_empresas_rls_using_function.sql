-- ==============================================================================
-- MIGRATION: Fix Empresas RLS using public.is_master()
-- ==============================================================================

DROP POLICY IF EXISTS "Master pode criar empresas" ON public.empresas;
CREATE POLICY "Master pode criar empresas"
    ON public.empresas FOR INSERT 
    WITH CHECK ( public.is_master() );

DROP POLICY IF EXISTS "Master pode atualizar empresas" ON public.empresas;
CREATE POLICY "Master pode atualizar empresas"
    ON public.empresas FOR UPDATE
    USING ( public.is_master() );
