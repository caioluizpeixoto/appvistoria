-- ==============================================================================
-- MIGRATION: 20260921_enable_wallet_enforcement.sql
-- DESCRIÇÃO: Ativa a cobrança e o débito real na carteira (financial_enforcement_enabled = true),
-- cadastra/atualiza tabela de preços dos serviços e refina authorize_paid_operation.
-- ==============================================================================

-- 1. ATIVAR A COBRANÇA FINANCEIRA REAL NO BANCO
INSERT INTO public.financial_settings (key, value, description)
VALUES (
    'enforcement',
    jsonb_build_object('financial_enforcement_enabled', true),
    'Determina se as operações devem ser bloqueadas ou debitadas por falta de saldo. ATIVADO.'
)
ON CONFLICT (key) DO UPDATE SET 
    value = jsonb_build_object('financial_enforcement_enabled', true),
    updated_at = timezone('utc'::text, now());

-- 2. ATUALIZAR / CADASTRAR TABELA DE PREÇOS DOS SERVIÇOS
INSERT INTO public.service_prices (service_code, name, price, active)
VALUES 
    -- Laudo de Vistoria
    ('VEHICLE_REPORT', 'Laudo de Vistoria em PDF', 15.00, true),
    
    -- Catálogo Radar Consultas
    ('auto_bin', 'Auto BIN', 7.66, true),
    ('bin_por_motor', 'BIN por Motor', 7.90, true),
    ('auto_pericia', 'Auto Perícia', 35.80, true),
    ('auto_pericia_hrf', 'Auto Perícia HRF', 28.90, true),
    ('auto_completa', 'Auto Completa', 60.91, true),
    ('auto_leilao', 'Auto Leilão', 21.24, true),
    ('auto_base_estadual', 'Auto Base Estadual', 12.90, true),
    ('auto_estadual_proprietario', 'Auto Estadual + Proprietário', 18.90, true),
    ('auto_decodificador_chassi', 'Auto Decodificador de Chassi', 9.90, true),
    ('auto_gravame', 'Auto Gravame', 12.50, true),
    ('auto_debitos_recall', 'Auto Débitos + Recall', 14.90, true),
    ('auto_analise', 'Auto Análise', 25.00, true),
    ('auto_analise_plus', 'Auto Análise +', 32.00, true),
    ('numero_crv', 'Número CRV', 12.00, true),
    ('codigo_crv', 'Código CRV', 12.00, true),
    ('e_crlv_nova', 'E-CRLV Nova', 25.00, true)
ON CONFLICT (service_code) DO UPDATE SET 
    price = EXCLUDED.price,
    name = EXCLUDED.name,
    active = EXCLUDED.active,
    updated_at = timezone('utc'::text, now());

-- 3. REFINAMENTO DA FUNÇÃO ATÔMICA DE AUTORIZAÇÃO E DÉBITO
CREATE OR REPLACE FUNCTION public.authorize_paid_operation(
    p_service_code TEXT,
    p_reference_type TEXT,
    p_reference_id TEXT,
    p_description TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_wallet public.wallets;
    v_price NUMERIC(12, 2);
    v_service_name TEXT;
    v_enforcement BOOLEAN;
    v_existing_tx public.wallet_transactions;
    v_new_balance NUMERIC(12, 2);
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'allowed', false, 
            'reason', 'UNAUTHENTICATED'
        );
    END IF;

    -- 1. Verificar se a operação com essa referência já foi cobrada/registrada anteriormente (Idempotência)
    IF p_reference_type IS NOT NULL AND p_reference_id IS NOT NULL THEN
        SELECT * INTO v_existing_tx
        FROM public.wallet_transactions
        WHERE company_id = v_user_id
          AND reference_type = p_reference_type
          AND reference_id = p_reference_id
          AND status = 'completed'
        LIMIT 1;

        IF FOUND THEN
            -- Já cobrado anteriormente, autoriza sem cobrar novamente
            RETURN jsonb_build_object(
                'allowed', true,
                'already_processed', true,
                'debited', false,
                'transaction_id', v_existing_tx.id,
                'balance', v_existing_tx.balance_after,
                'service_code', p_service_code
            );
        END IF;
    END IF;

    -- 2. Buscar preço e nome do serviço
    SELECT price, name INTO v_price, v_service_name
    FROM public.service_prices
    WHERE service_code = p_service_code AND active = true;

    IF NOT FOUND THEN
        v_price := 0.00;
        v_service_name := COALESCE(p_description, p_service_code);
    END IF;

    -- 3. Obter carteira com lock de linha (FOR UPDATE) para evitar race condition
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE company_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.wallets (company_id, balance, grace_operations_used)
        VALUES (v_user_id, 0.00, 0)
        RETURNING * INTO v_wallet;
    END IF;

    -- 4. Verificar se a cobrança financeira está ativada
    v_enforcement := public.is_financial_enforcement_enabled();

    -- CASO A: financial_enforcement_enabled = FALSE
    -- Permitir sempre, NÃO debitar saldo, apenas registrar consumo (type = 'usage')
    IF NOT v_enforcement THEN
        INSERT INTO public.wallet_transactions (
            company_id,
            wallet_id,
            type,
            amount,
            description,
            reference_type,
            reference_id,
            balance_before,
            balance_after,
            status,
            used_grace_operation
        ) VALUES (
            v_user_id,
            v_wallet.id,
            'usage',
            v_price,
            COALESCE(p_description, v_service_name || ' (Consumo Registrado)'),
            p_reference_type,
            p_reference_id,
            v_wallet.balance,
            v_wallet.balance,
            'completed',
            false
        );

        RETURN jsonb_build_object(
            'allowed', true,
            'enforcement_enabled', false,
            'already_processed', false,
            'debited', false,
            'balance', v_wallet.balance,
            'grace_operations_used', v_wallet.grace_operations_used,
            'consumed_amount', v_price,
            'price', v_price,
            'service_name', v_service_name
        );
    END IF;

    -- CASO B: financial_enforcement_enabled = TRUE
    -- Caso B1: Saldo suficiente
    IF v_wallet.balance >= v_price THEN
        v_new_balance := v_wallet.balance - v_price;

        UPDATE public.wallets
        SET balance = v_new_balance,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_wallet.id;

        INSERT INTO public.wallet_transactions (
            company_id,
            wallet_id,
            type,
            amount,
            description,
            reference_type,
            reference_id,
            balance_before,
            balance_after,
            status,
            used_grace_operation
        ) VALUES (
            v_user_id,
            v_wallet.id,
            'debit',
            v_price,
            COALESCE(p_description, v_service_name),
            p_reference_type,
            p_reference_id,
            v_wallet.balance,
            v_new_balance,
            'completed',
            false
        );

        RETURN jsonb_build_object(
            'allowed', true,
            'enforcement_enabled', true,
            'already_processed', false,
            'debited', true,
            'balance', v_new_balance,
            'grace_operations_used', v_wallet.grace_operations_used,
            'price', v_price,
            'service_name', v_service_name
        );

    -- Caso B2: Saldo insuficiente mas possui tolerância (< 2)
    ELSIF v_wallet.grace_operations_used < 2 THEN
        v_new_balance := v_wallet.balance - v_price;

        UPDATE public.wallets
        SET balance = v_new_balance,
            grace_operations_used = grace_operations_used + 1,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_wallet.id;

        INSERT INTO public.wallet_transactions (
            company_id,
            wallet_id,
            type,
            amount,
            description,
            reference_type,
            reference_id,
            balance_before,
            balance_after,
            status,
            used_grace_operation
        ) VALUES (
            v_user_id,
            v_wallet.id,
            'debit',
            v_price,
            COALESCE(p_description, v_service_name || ' (Operação em Tolerância)'),
            p_reference_type,
            p_reference_id,
            v_wallet.balance,
            v_new_balance,
            'completed',
            true
        );

        RETURN jsonb_build_object(
            'allowed', true,
            'enforcement_enabled', true,
            'already_processed', false,
            'debited', true,
            'used_grace_operation', true,
            'grace_operations_used', v_wallet.grace_operations_used + 1,
            'balance', v_new_balance,
            'price', v_price,
            'service_name', v_service_name
        );

    -- Caso B3: Saldo insuficiente e sem tolerância restante
    ELSE
        RETURN jsonb_build_object(
            'allowed', false,
            'enforcement_enabled', true,
            'already_processed', false,
            'debited', false,
            'reason', 'INSUFFICIENT_BALANCE_AND_GRACE_EXHAUSTED',
            'balance', v_wallet.balance,
            'grace_operations_used', v_wallet.grace_operations_used,
            'price', v_price,
            'service_name', v_service_name
        );
    END IF;
END;
$$;
