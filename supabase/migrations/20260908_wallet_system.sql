-- ==============================================================================
-- MIGRATION: 20260908_wallet_system.sql
-- DESCRIÇÃO: Sistema Financeiro de Créditos/Carteira Pré-Paga e Auditoria de Consumo
-- ==============================================================================

-- 1. CONFIGURAÇÕES FINANCEIRAS GLOBAIS
CREATE TABLE IF NOT EXISTS public.financial_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Inserir configuração inicial com financial_enforcement_enabled = false
INSERT INTO public.financial_settings (key, value, description)
VALUES (
    'enforcement',
    jsonb_build_object('financial_enforcement_enabled', false),
    'Determina se as operações devem ser bloqueadas ou debitadas por falta de saldo. Atualmente FALSE.'
)
ON CONFLICT (key) DO NOTHING;

-- 2. TABELA DE PREÇOS DE SERVIÇOS
CREATE TABLE IF NOT EXISTS public.service_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (price >= 0),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Preços padrões iniciais
INSERT INTO public.service_prices (service_code, name, price, active)
VALUES 
    ('VEHICLE_BASIC', 'Pesquisa Veicular Básica', 4.90, true),
    ('VEHICLE_COMPLETE', 'Pesquisa Veicular Completa', 9.90, true),
    ('BIN_CONSULTA', 'Consulta BIN', 3.50, true),
    ('VEHICLE_REPORT', 'Laudo de Vistoria', 15.00, true)
ON CONFLICT (service_code) DO NOTHING;

-- 3. TABELA DE CARTEIRAS (WALLETS)
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0.00),
    grace_operations_used INT NOT NULL DEFAULT 0 CHECK (grace_operations_used >= 0 AND grace_operations_used <= 2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_wallets_company_id ON public.wallets(company_id);

-- 4. TABELA DE MOVIMENTAÇÕES (WALLET_TRANSACTIONS)
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('credit', 'debit', 'usage')),
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (amount >= 0.00),
    description TEXT NOT NULL,
    reference_type TEXT,
    reference_id TEXT,
    balance_before NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    balance_after NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled', 'failed')),
    used_grace_operation BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_wallet_tx_company ON public.wallet_transactions(company_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet ON public.wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_reference ON public.wallet_transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_created ON public.wallet_transactions(created_at DESC);

-- 5. TABELA DE RECARGAS (RECHARGES)
CREATE TABLE IF NOT EXISTS public.recharges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0.00),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'expired', 'cancelled', 'failed')),
    payment_method TEXT NOT NULL DEFAULT 'pix',
    provider TEXT NOT NULL DEFAULT 'sicredi_future',
    external_id TEXT,
    txid TEXT,
    pix_copy_paste TEXT,
    qr_code_data TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    paid_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_recharges_company ON public.recharges(company_id);
CREATE INDEX IF NOT EXISTS idx_recharges_wallet ON public.recharges(wallet_id);
CREATE INDEX IF NOT EXISTS idx_recharges_status ON public.recharges(status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_recharges_txid ON public.recharges(txid) WHERE txid IS NOT NULL;

-- 6. HABILITAR ROW LEVEL SECURITY (RLS)
ALTER TABLE public.financial_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recharges ENABLE ROW LEVEL SECURITY;

-- POLICIES:
-- Leitura pública / autenticada das configurações e preços
CREATE POLICY "financial_settings_select_policy" ON public.financial_settings
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "service_prices_select_policy" ON public.service_prices
    FOR SELECT USING (auth.role() = 'authenticated');

-- Carteira: usuário autenticado só pode ver a carteira da sua própria empresa
CREATE POLICY "wallets_select_own" ON public.wallets
    FOR SELECT USING (auth.uid() = company_id);

-- Transações: usuário autenticado só pode ver transações da sua própria empresa
CREATE POLICY "wallet_transactions_select_own" ON public.wallet_transactions
    FOR SELECT USING (auth.uid() = company_id);

-- Recargas: usuário só vê recargas da sua empresa e pode solicitar (INSERT) recarga pendente
CREATE POLICY "recharges_select_own" ON public.recharges
    FOR SELECT USING (auth.uid() = company_id);

CREATE POLICY "recharges_insert_own" ON public.recharges
    FOR INSERT WITH CHECK (auth.uid() = company_id AND status = 'pending');

-- 7. FUNÇÕES E PROCEDURES ATÔMICAS NO POSTGRESQL

-- Helper: Verifica se a cobrança financeira está ativada
CREATE OR REPLACE FUNCTION public.is_financial_enforcement_enabled()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_enabled BOOLEAN;
BEGIN
    SELECT (value->>'financial_enforcement_enabled')::BOOLEAN
    INTO v_enabled
    FROM public.financial_settings
    WHERE key = 'enforcement';

    RETURN COALESCE(v_enabled, false);
END;
$$;

-- Helper: Obtém ou inicializa a carteira para o usuário autenticado
CREATE OR REPLACE FUNCTION public.get_or_create_wallet()
RETURNS public.wallets
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_wallet public.wallets;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado';
    END IF;

    SELECT * INTO v_wallet FROM public.wallets WHERE company_id = v_user_id;

    IF NOT FOUND THEN
        INSERT INTO public.wallets (company_id, balance, grace_operations_used)
        VALUES (v_user_id, 0.00, 0)
        ON CONFLICT (company_id) DO UPDATE SET updated_at = timezone('utc'::text, now())
        RETURNING * INTO v_wallet;
    END IF;

    RETURN v_wallet;
END;
$$;

-- FUNÇÃO CENTRAL: authorize_paid_operation
-- Executa a validação e o registro atômico com proteção contra race conditions e cobrança duplicada.
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
    v_used_grace BOOLEAN := false;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('allowed', false, 'reason', 'UNAUTHENTICATED');
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
                'transaction_id', v_existing_tx.id,
                'balance', v_existing_tx.balance_after
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
    -- Permitir sempre, NÃO debitar saldo, NÃO usar tolerância, apenas registrar consumo (type = 'usage')
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
            'balance', v_wallet.balance,
            'grace_operations_used', v_wallet.grace_operations_used,
            'consumed_amount', v_price
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
            'debited', true,
            'balance', v_new_balance,
            'grace_operations_used', v_wallet.grace_operations_used
        );

    -- Caso B2: Saldo insuficiente mas possui tolerância (< 2)
    ELSIF v_wallet.grace_operations_used < 2 THEN
        UPDATE public.wallets
        SET grace_operations_used = grace_operations_used + 1,
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
            'usage',
            v_price,
            COALESCE(p_description, v_service_name || ' (Operação em Tolerância)'),
            p_reference_type,
            p_reference_id,
            v_wallet.balance,
            v_wallet.balance,
            'completed',
            true
        );

        RETURN jsonb_build_object(
            'allowed', true,
            'enforcement_enabled', true,
            'used_grace_operation', true,
            'grace_operations_used', v_wallet.grace_operations_used + 1,
            'grace_operations_remaining', 2 - (v_wallet.grace_operations_used + 1),
            'balance', v_wallet.balance
        );

    -- Caso B3: Saldo insuficiente e tolerância esgotada (grace_operations_used >= 2)
    ELSE
        RETURN jsonb_build_object(
            'allowed', false,
            'enforcement_enabled', true,
            'reason', 'INSUFFICIENT_BALANCE_AND_GRACE_EXHAUSTED',
            'balance', v_wallet.balance,
            'grace_operations_used', v_wallet.grace_operations_used
        );
    END IF;
END;
$$;

-- FUNÇÃO CENTRAL: process_recharge_payment
-- Processa o pagamento de uma recarga de forma atômica e idempotente
CREATE OR REPLACE FUNCTION public.process_recharge_payment(
    p_recharge_id UUID,
    p_txid TEXT DEFAULT NULL,
    p_external_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_recharge public.recharges;
    v_wallet public.wallets;
    v_old_balance NUMERIC(12, 2);
    v_new_balance NUMERIC(12, 2);
BEGIN
    -- 1. Buscar a recarga com bloqueio exclusivo
    SELECT * INTO v_recharge
    FROM public.recharges
    WHERE id = p_recharge_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'RECHARGE_NOT_FOUND');
    END IF;

    -- 2. Idempotência: se já foi paga, retornar sucesso sem creditar novamente
    IF v_recharge.status = 'paid' THEN
        RETURN jsonb_build_object(
            'success', true,
            'already_processed', true,
            'recharge_id', v_recharge.id,
            'amount', v_recharge.amount
        );
    END IF;

    IF v_recharge.status != 'pending' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INVALID_RECHARGE_STATUS',
            'current_status', v_recharge.status
        );
    END IF;

    -- 3. Buscar carteira vinculada com bloqueio
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE id = v_recharge.wallet_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'WALLET_NOT_FOUND');
    END IF;

    v_old_balance := v_wallet.balance;
    v_new_balance := v_old_balance + v_recharge.amount;

    -- 4. Atualizar saldo e resetar tolerância para 0
    UPDATE public.wallets
    SET balance = v_new_balance,
        grace_operations_used = 0,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_wallet.id;

    -- 5. Atualizar recarga para 'paid'
    UPDATE public.recharges
    SET status = 'paid',
        paid_at = timezone('utc'::text, now()),
        txid = COALESCE(p_txid, txid),
        external_id = COALESCE(p_external_id, external_id)
    WHERE id = v_recharge.id;

    -- 6. Registrar transação de crédito
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
        v_recharge.company_id,
        v_wallet.id,
        'credit',
        v_recharge.amount,
        'Recarga de saldo via Pix',
        'recharge',
        v_recharge.id::TEXT,
        v_old_balance,
        v_new_balance,
        'completed',
        false
    );

    RETURN jsonb_build_object(
        'success', true,
        'recharge_id', v_recharge.id,
        'balance_before', v_old_balance,
        'balance_after', v_new_balance,
        'grace_operations_used', 0
    );
END;
$$;
