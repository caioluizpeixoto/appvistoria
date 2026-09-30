-- MIGRATION: 20260929_master_remove_credits.sql
-- DESCRIÇÃO: Função RPC segura para o Master remover créditos (tirar saldo)

CREATE OR REPLACE FUNCTION public.master_remove_credits(target_company_id UUID, amount NUMERIC, description TEXT)
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
        RAISE EXCEPTION 'O valor a remover deve ser maior que zero.';
    END IF;

    -- Resgatar carteira (bloqueando a linha para update seguro)
    SELECT id, balance INTO v_wallet_id, v_balance_before
    FROM public.wallets
    WHERE company_id = target_company_id
    FOR UPDATE;

    IF NOT FOUND THEN
        -- Se não tiver carteira, criamos uma nova já com o saldo negativo
        INSERT INTO public.wallets (company_id, balance)
        VALUES (target_company_id, -amount)
        RETURNING id, balance INTO v_wallet_id, v_balance_after;
        
        v_balance_before := 0;
    ELSE
        -- Deduz o saldo
        UPDATE public.wallets
        SET balance = balance - amount,
            updated_at = NOW()
        WHERE id = v_wallet_id
        RETURNING balance INTO v_balance_after;
    END IF;

    -- Grava a transação no histórico
    INSERT INTO public.wallet_transactions (
        wallet_id,
        amount,
        balance_before,
        balance_after,
        type,
        description,
        reference_id
    ) VALUES (
        v_wallet_id,
        -amount, -- Amount é negativo para representar débito
        v_balance_before,
        v_balance_after,
        'master_debit',
        description,
        'manual-debit-' || gen_random_uuid()::text
    );

    RETURN TRUE;
END;
$$;
