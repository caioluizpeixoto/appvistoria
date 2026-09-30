-- Permitir que o master delete empresas
DROP POLICY IF EXISTS "Master pode deletar empresas" ON public.empresas;
CREATE POLICY "Master pode deletar empresas"
    ON public.empresas FOR DELETE
    USING ( public.is_master() );
