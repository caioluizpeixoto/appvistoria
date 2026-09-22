-- ==============================================================================
-- MIGRATION: 20260921_master_add_credits.sql
-- DESCRIÇÃO: Funções RPC seguras para o Master listar carteiras e adicionar créditos
-- ==============================================================================

-- 1. RPC: Listar todas as carteiras e saldos para o Master
CREATE OR REPLACE FUNCTION public.get_wallets_master()
RETURNS TABLE (
    company_id UUID,
    balance NUMERIC(12, 2),
    empresa_nome TEXT,
    email TEXT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT 
        w.company_id, 
        w.balance, 
        COALESCE(
           (SELECT v.empresa_nome FROM public.vistorias_cloud v WHERE v.user_id = w.company_id LIMIT 1),
           'Empresa ' || SUBSTRING(w.company_id::text, 1, 8)
        ) as empresa_nome,
        u.email
    FROM public.wallets w
    JOIN auth.users u ON u.id = w.company_id
    ORDER BY w.balance DESC;
$$;

-- 2. RPC: Adicionar créditos a uma carteira específica (Apenas Master)
CREATE OR REPLACE FUNCTION public.master_add_credits(target_company_id UUID, amount NUMERIC, description TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_wallet_id UUID;
    v_balance_before NUMERIC(12, 2);
    v_balance_after NUMERIC(12, 2);
BEGIN
    -- Validação de segurança: Apenas master
    IF NOT public.is_master() THEN
        RAISE EXCEPTION 'Acesso negado: apenas perfil master tem permissão para acessar esta função.';
    END IF;

    -- Validação de valor
    IF amount <= 0 THEN
        RAISE EXCEPTION 'O valor a adicionar deve ser maior que zero.';
    END IF;

    -- Resgatar carteira (bloqueando a linha para update seguro)
    SELECT id, balance INTO v_wallet_id, v_balance_before 
    FROM public.wallets 
    WHERE company_id = target_company_id 
    FOR UPDATE;

    IF v_wallet_id IS NULL THEN
        RAISE EXCEPTION 'Carteira não encontrada para esta empresa.';
    END IF;

    -- Calcular novo saldo
    v_balance_after := v_balance_before + amount;

    -- Atualizar saldo
    UPDATE public.wallets 
    SET balance = v_balance_after, updated_at = NOW() 
    WHERE id = v_wallet_id;

    -- Inserir transação de estorno/crédito master
    INSERT INTO public.wallet_transactions (
        company_id, wallet_id, type, amount, description, reference_type, balance_before, balance_after, status
    ) VALUES (
        target_company_id, v_wallet_id, 'credit', amount, description, 'master_credit', v_balance_before, v_balance_after, 'completed'
    );

    RETURN TRUE;
END;
$$;
