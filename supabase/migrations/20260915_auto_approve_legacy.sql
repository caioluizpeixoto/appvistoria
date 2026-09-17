-- ==============================================================================
-- MIGRATION: 20260915_auto_approve_legacy.sql
-- DESCRIÇÃO: Atualiza a RPC para refletir a nova regra (Login primeiro)
-- ==============================================================================

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
        -- Novo dispositivo: insere como pendente (já que agora todos passam pelo login antes)
        INSERT INTO public.dispositivos_autorizados (
            device_id,
            device_model,
            sistema_operacional,
            solicitante_nome,
            solicitante_telefone,
            user_id,
            status,
            aprovado_em,
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
            NULL,
            NOW(),
            NOW()
        )
        RETURNING * INTO v_registro;
    ELSE
        -- Dispositivo existente: atualiza informações e última atividade
        UPDATE public.dispositivos_autorizados
        SET
            ultima_atividade = NOW(),
            device_model = COALESCE(NULLIF(TRIM(p_device_model), ''), device_model),
            sistema_operacional = COALESCE(NULLIF(TRIM(p_sistema_operacional), ''), sistema_operacional),
            solicitante_nome = COALESCE(NULLIF(TRIM(p_solicitante_nome), ''), solicitante_nome),
            solicitante_telefone = COALESCE(NULLIF(TRIM(p_solicitante_telefone), ''), solicitante_telefone),
            user_id = COALESCE(p_user_id, user_id)
        WHERE id = v_registro.id
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
