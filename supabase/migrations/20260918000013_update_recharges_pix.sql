-- ==============================================================================
-- MIGRATION: 20260918_update_recharges_pix.sql
-- DESCRIÇÃO: Ajustes na tabela recharges para a infraestrutura do Pix Sicredi
-- ==============================================================================

-- 1. Adicionar colunas de controle para webhook / auditoria
ALTER TABLE public.recharges 
ADD COLUMN IF NOT EXISTS end_to_end_id TEXT,
ADD COLUMN IF NOT EXISTS error_message TEXT,
ADD COLUMN IF NOT EXISTS processed_at TIMESTAMPTZ;

-- 2. Garantir que o txid é único
CREATE UNIQUE INDEX IF NOT EXISTS idx_recharges_txid_real ON public.recharges(txid) WHERE txid IS NOT NULL;

-- 3. Revogar o direito do app/frontend de inserir diretamente uma solicitação de recarga.
-- As recargas a partir de agora DEVEM ser criadas apenas pela Edge Function backend
-- para evitar falsificações de amount. O usuário autenticado só pode VER suas recargas.
DROP POLICY IF EXISTS "recharges_insert_own" ON public.recharges;
