-- ==============================================================================
-- MIGRATION: 20260918_update_recharges_pix_sicredi.sql
-- DESCRIÇÃO: Adiciona campos necessários para integração completa do PIX Sicredi
-- ==============================================================================

-- Adiciona campos na tabela recharges para rastreamento completo PIX
ALTER TABLE public.recharges
ADD COLUMN IF NOT EXISTS e2eid TEXT,
ADD COLUMN IF NOT EXISTS location TEXT,
ADD COLUMN IF NOT EXISTS provider_response JSONB;

-- e2eid deve ser único caso exista (evita processar o mesmo PIX recebido duas vezes se provider falhar no txid)
CREATE UNIQUE INDEX IF NOT EXISTS idx_recharges_e2eid ON public.recharges(e2eid) WHERE e2eid IS NOT NULL;

-- Adicionar policy extra para visualização, garantindo que o provider_response não seja vazado publicamente
-- Como RLS já protege a tabela, não precisamos fazer deny no column level unless absolutely necessary,
-- Apenas garantindo que RLS está habilitado:
-- ALTER TABLE public.recharges ENABLE ROW LEVEL SECURITY;
