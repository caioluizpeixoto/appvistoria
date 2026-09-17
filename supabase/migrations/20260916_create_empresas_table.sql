-- ==============================================================================
-- MIGRATION: Criar tabela de Empresas (Multi-Tenant)
-- DATA: 2026-09-16
-- DESCRIÇÃO: Cria a tabela oficial de empresas para substituir valores fixos no código.
-- ==============================================================================

-- 1. Criar a tabela
CREATE TABLE IF NOT EXISTS public.empresas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    razao_social TEXT NOT NULL,
    nome_fantasia TEXT,
    cnpj TEXT UNIQUE,
    endereco TEXT,
    contato TEXT,
    email TEXT,
    telefone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Habilitar RLS
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de Segurança (Policies)
-- Master pode ler todas as empresas
CREATE POLICY "Master pode ver todas as empresas" 
    ON public.empresas FOR SELECT 
    USING (
        (SELECT (auth.jwt() ->> 'is_master')::boolean) = true 
        OR 
        (SELECT (auth.jwt() ->> 'role') = 'master')
    );

-- Usuários comuns (vistoriadores) podem ver a própria empresa baseados no CNPJ do auth
CREATE POLICY "Usuários veem a própria empresa" 
    ON public.empresas FOR SELECT 
    USING (
        cnpj = (SELECT (auth.jwt() ->> 'cnpj'))
    );

-- 4. Inserir as empresas oficiais (Seeds)
INSERT INTO public.empresas (razao_social, cnpj, endereco, contato, email) VALUES
('ULTRA VISÃO INDAIATUBA', '08420171000181', '08.420.171/0001-81 - RUA AUGUSTO DE OLIVEIRA CAMARGO, 321 - CENTRO - INDAIATUBA - SP - CEP 13330-160 - TEL (19) 3885-0007', 'SUPORTE@ULTRAVISAO.COM.BR', '08420171000181'),
('ULTRA VISÃO SALTO', '08420171000424', '08.420.171/0004-24 - R. SETE DE SETEMBRO, 1111 - VILA HENRIQUE - SALTO - SP - CEP 13320-040 - TEL (11) 94705-6608', 'SALTO@ULTRAVISAO.COM.BR', '08420171000424'),
('ULTRA VISÃO MONTE MOR', '22931906000162', '22.931.906/0001-62 - R. CHEQUER ASSIS, 321 - JD GUANABARA - MONTE MOR - SP - CEP 13190-000 - TEL (19) 3217-7723', 'MONTEMOR@ULTRAVISAO.COM.BR', '22931906000162'),
('AUTO PROVE VISTORIAS', '24868718000162', '24.868.718/0001-62 - RUA SETE DE ABRIL 541 CENTRO COSMOPOLIS SP - CEP 13.150.610 - TEL 19 3872-1891', 'COSMOPOLIS@ULTRAVISAO.COM.BR', '24868718000162'),
('SUMARÉ VISTORIAS', '11977969000133', '11.977.969/0001-33 - AV REBOUÇAS 1989 - SUMARÉ - SP - CEP 13170-275 - TEL 19 3306.8604', 'SUMARE@APPVISTORIA.COM.BR', '11977969000133')
ON CONFLICT (cnpj) DO NOTHING;

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_empresas_modtime ON public.empresas;
CREATE TRIGGER update_empresas_modtime
    BEFORE UPDATE ON public.empresas
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();
