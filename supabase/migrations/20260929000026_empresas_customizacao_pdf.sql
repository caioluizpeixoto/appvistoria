-- ==============================================================================
-- MIGRATION: Adicionar customização visual nas empresas
-- DATA: 2026-09-29
-- DESCRIÇÃO: Adiciona colunas para cor, logo do topo e logo de marca d'água
-- ==============================================================================

ALTER TABLE public.empresas
ADD COLUMN IF NOT EXISTS cor_pdf TEXT,
ADD COLUMN IF NOT EXISTS logo_topo_url TEXT,
ADD COLUMN IF NOT EXISTS logo_marca_dagua_url TEXT;
