CREATE OR REPLACE FUNCTION public.refund_paid_operation(
    p_reference_id TEXT,
    p_reason TEXT DEFAULT 'Estorno por falha na integração'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tx public.wallet_transactions;
    v_wallet public.wallets;
    v_new_balance NUMERIC(12, 2);
BEGIN
    -- Procurar a transação de débito original (status = completed, type = debit ou usage)
    SELECT * INTO v_tx
    FROM public.wallet_transactions
    WHERE reference_id = p_reference_id
      AND reference_type = 'radar_pesquisa'
      AND status = 'completed'
      AND amount > 0
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'reason', 'Transação original não encontrada ou valor é 0.');
    END IF;

    -- Obter carteira com lock (serializa qualquer tentativa concorrente)
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE id = v_tx.wallet_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'reason', 'Carteira não encontrada.');
    END IF;

    -- Verificar se já existe um estorno para esse reference_id APÓS o lock
    IF EXISTS (
        SELECT 1 FROM public.wallet_transactions
        WHERE reference_id = p_reference_id
          AND reference_type = 'radar_pesquisa_estorno'
          AND status = 'completed'
    ) THEN
        RETURN jsonb_build_object('success', true, 'reason', 'Estorno já realizado anteriormente.');
    END IF;

    -- Se usou operação de carência, devolve a carência
    IF v_tx.used_grace_operation = true THEN
        UPDATE public.wallets
        SET grace_operations_used = GREATEST(0, grace_operations_used - 1)
        WHERE id = v_wallet.id;

        -- Insere transação de estorno (valor 0, apenas devolvendo a cota)
        INSERT INTO public.wallet_transactions (
            company_id, wallet_id, type, amount, description, reference_type, reference_id, balance_before, balance_after, status
        ) VALUES (
            v_tx.company_id, v_wallet.id, 'credit', 0, p_reason, 'radar_pesquisa_estorno', p_reference_id, v_wallet.balance, v_wallet.balance, 'completed'
        );

        RETURN jsonb_build_object('success', true, 'refunded_amount', 0, 'grace_operation_refunded', true);
    ELSE
        -- Estorno real em dinheiro
        v_new_balance := v_wallet.balance + v_tx.amount;

        UPDATE public.wallets
        SET balance = v_new_balance
        WHERE id = v_wallet.id;

        INSERT INTO public.wallet_transactions (
            company_id, wallet_id, type, amount, description, reference_type, reference_id, balance_before, balance_after, status
        ) VALUES (
            v_tx.company_id, v_wallet.id, 'credit', v_tx.amount, p_reason, 'radar_pesquisa_estorno', p_reference_id, v_wallet.balance, v_new_balance, 'completed'
        );

        RETURN jsonb_build_object('success', true, 'refunded_amount', v_tx.amount, 'grace_operation_refunded', false);
    END IF;
END;
$$;
