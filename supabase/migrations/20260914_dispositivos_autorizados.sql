-- ==============================================================================
-- MIGRATION: 20260914_dispositivos_autorizados.sql
-- DESCRIÇÃO: Trava de segurança para aprovação de celulares/aparelhos pelo Master
-- ==============================================================================

-- 1. CRIAR TABELA DE DISPOSITIVOS AUTORIZADOS
CREATE TABLE IF NOT EXISTS public.dispositivos_autorizados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL UNIQUE,
    device_model TEXT,
    sistema_operacional TEXT,
    solicitante_nome TEXT,
    solicitante_telefone TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'bloqueado')),
    motivo_bloqueio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    aprovado_em TIMESTAMPTZ,
    aprovado_por UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ultima_atividade TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices de performance
CREATE INDEX IF NOT EXISTS idx_dispositivos_device_id ON public.dispositivos_autorizados(device_id);
CREATE INDEX IF NOT EXISTS idx_dispositivos_status ON public.dispositivos_autorizados(status);
CREATE INDEX IF NOT EXISTS idx_dispositivos_created_at ON public.dispositivos_autorizados(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dispositivos_user_id ON public.dispositivos_autorizados(user_id);

-- 2. HABILITAR ROW LEVEL SECURITY (RLS)
ALTER TABLE public.dispositivos_autorizados ENABLE ROW LEVEL SECURITY;

-- 3. POLÍTICAS DE RLS
-- Dispositivos podem registrar uma solicitação inicial (INSERT)
DROP POLICY IF EXISTS "Qualquer app pode solicitar cadastro de dispositivo" ON public.dispositivos_autorizados;
CREATE POLICY "Qualquer app pode solicitar cadastro de dispositivo"
    ON public.dispositivos_autorizados FOR INSERT
    WITH CHECK (true);

-- Dispositivos podem ler o seu próprio status
DROP POLICY IF EXISTS "Dispositivo pode ler seu próprio status" ON public.dispositivos_autorizados;
CREATE POLICY "Dispositivo pode ler seu próprio status"
    ON public.dispositivos_autorizados FOR SELECT
    USING (true);

-- Master tem controle absoluto (SELECT, UPDATE, DELETE)
DROP POLICY IF EXISTS "Master tem controle total sobre dispositivos" ON public.dispositivos_autorizados;
CREATE POLICY "Master tem controle total sobre dispositivos"
    ON public.dispositivos_autorizados FOR ALL
    USING (public.is_master())
    WITH CHECK (public.is_master());

-- 4. RPC: REGISTRAR OU CONSULTAR DISPOSITIVO
-- Chamada ao abrir o aplicativo no aparelho do usuário
CREATE OR REPLACE FUNCTION public.registrar_ou_consultar_dispositivo(
    p_device_id TEXT,
    p_device_model TEXT DEFAULT NULL,
    p_sistema_operacional TEXT DEFAULT NULL,
    p_solicitante_nome TEXT DEFAULT NULL,
    p_solicitante_telefone TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    device_id TEXT,
    status TEXT,
    solicitante_nome TEXT,
    aprovado_em TIMESTAMPTZ,
    motivo_bloqueio TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_registro RECORD;
BEGIN
    SELECT * INTO v_registro
    FROM public.dispositivos_autorizados d
    WHERE d.device_id = p_device_id;

    IF v_registro.id IS NULL THEN
        -- Novo dispositivo: insere como 'pendente'
        INSERT INTO public.dispositivos_autorizados (
            device_id,
            device_model,
            sistema_operacional,
            solicitante_nome,
            solicitante_telefone,
            user_id,
            status,
            created_at,
            ultima_atividade
        ) VALUES (
            p_device_id,
            COALESCE(p_device_model, 'Aparelho Desconhecido'),
            COALESCE(p_sistema_operacional, 'Desconhecido'),
            NULLIF(TRIM(p_solicitante_nome), ''),
            NULLIF(TRIM(p_solicitante_telefone), ''),
            p_user_id,
            'pendente',
            NOW(),
            NOW()
        )
        RETURNING * INTO v_registro;
    ELSE
        -- Dispositivo existente: atualiza última atividade e informações atualizadas
        UPDATE public.dispositivos_autorizados d
        SET
            ultima_atividade = NOW(),
            device_model = COALESCE(NULLIF(TRIM(p_device_model), ''), d.device_model),
            sistema_operacional = COALESCE(NULLIF(TRIM(p_sistema_operacional), ''), d.sistema_operacional),
            solicitante_nome = COALESCE(NULLIF(TRIM(p_solicitante_nome), ''), d.solicitante_nome),
            solicitante_telefone = COALESCE(NULLIF(TRIM(p_solicitante_telefone), ''), d.solicitante_telefone),
            user_id = COALESCE(p_user_id, d.user_id)
        WHERE d.id = v_registro.id
        RETURNING * INTO v_registro;
    END IF;

    RETURN QUERY
    SELECT 
        v_registro.device_id,
        v_registro.status,
        v_registro.solicitante_nome,
        v_registro.aprovado_em,
        v_registro.motivo_bloqueio;
END;
$$;

-- 5. RPC: APROVAR DISPOSITIVO (Apenas Master)
CREATE OR REPLACE FUNCTION public.aprovar_dispositivo(p_device_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_master() THEN
        RAISE EXCEPTION 'Acesso negado: apenas o perfil master pode aprovar dispositivos.';
    END IF;

    UPDATE public.dispositivos_autorizados
    SET 
        status = 'aprovado',
        aprovado_em = NOW(),
        aprovado_por = auth.uid(),
        motivo_bloqueio = NULL
    WHERE device_id = p_device_id;

    RETURN FOUND;
END;
$$;

-- 6. RPC: BLOQUEAR DISPOSITIVO (Apenas Master)
CREATE OR REPLACE FUNCTION public.bloquear_dispositivo(
    p_device_id TEXT,
    p_motivo TEXT DEFAULT 'Acesso revogado pelo Administrador Master'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_master() THEN
        RAISE EXCEPTION 'Acesso negado: apenas o perfil master pode bloquear dispositivos.';
    END IF;

    UPDATE public.dispositivos_autorizados
    SET 
        status = 'bloqueado',
        motivo_bloqueio = p_motivo
    WHERE device_id = p_device_id;

    RETURN FOUND;
END;
$$;

-- 7. RPC: LISTAR DISPOSITIVOS PARA O PAINEL MASTER (Apenas Master)
CREATE OR REPLACE FUNCTION public.listar_dispositivos_master()
RETURNS TABLE (
    id UUID,
    device_id TEXT,
    device_model TEXT,
    sistema_operacional TEXT,
    solicitante_nome TEXT,
    solicitante_telefone TEXT,
    user_id UUID,
    status TEXT,
    motivo_bloqueio TEXT,
    created_at TIMESTAMPTZ,
    aprovado_em TIMESTAMPTZ,
    ultima_atividade TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_master() THEN
        RAISE EXCEPTION 'Acesso negado: apenas o perfil master pode listar dispositivos.';
    END IF;

    RETURN QUERY
    SELECT 
        d.id,
        d.device_id,
        d.device_model,
        d.sistema_operacional,
        d.solicitante_nome,
        d.solicitante_telefone,
        d.user_id,
        d.status,
        d.motivo_bloqueio,
        d.created_at,
        d.aprovado_em,
        d.ultima_atividade
    FROM public.dispositivos_autorizados d
    ORDER BY 
        CASE 
            WHEN d.status = 'pendente' THEN 0 
            WHEN d.status = 'bloqueado' THEN 2
            ELSE 1 
        END,
        d.created_at DESC;
END;
$$;

-- 8. RPC: REMOVER DISPOSITIVO (Apenas Master)
CREATE OR REPLACE FUNCTION public.remover_dispositivo_master(p_device_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.is_master() THEN
        RAISE EXCEPTION 'Acesso negado: apenas o perfil master pode remover dispositivos.';
    END IF;

    DELETE FROM public.dispositivos_autorizados
    WHERE device_id = p_device_id;

    RETURN FOUND;
END;
$$;
