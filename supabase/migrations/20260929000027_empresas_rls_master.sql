-- Permitir que o master crie empresas
DROP POLICY IF EXISTS "Master pode criar empresas" ON public.empresas;
CREATE POLICY "Master pode criar empresas"
    ON public.empresas FOR INSERT 
    WITH CHECK (
        (SELECT (auth.jwt() ->> 'is_master')::boolean) = true 
        OR 
        (SELECT (auth.jwt() ->> 'role') = 'master')
    );

-- Permitir que o master atualize empresas
DROP POLICY IF EXISTS "Master pode atualizar empresas" ON public.empresas;
CREATE POLICY "Master pode atualizar empresas"
    ON public.empresas FOR UPDATE
    USING (
        (SELECT (auth.jwt() ->> 'is_master')::boolean) = true 
        OR 
        (SELECT (auth.jwt() ->> 'role') = 'master')
    );