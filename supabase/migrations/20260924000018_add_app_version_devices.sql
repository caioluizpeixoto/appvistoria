-- Adiciona coluna app_version
ALTER TABLE public.dispositivos_autorizados ADD COLUMN IF NOT EXISTS app_version TEXT;

-- Atualiza a função RPC para aceitar e gravar p_app_version
DROP FUNCTION IF EXISTS public.registrar_ou_consultar_dispositivo(text, text, text, text, text, uuid);
DROP FUNCTION IF EXISTS public.registrar_ou_consultar_dispositivo(text, text, text, text, text, uuid, text);
CREATE OR REPLACE FUNCTION public.registrar_ou_consultar_dispositivo(
    p_device_id text,
    p_device_model text,
    p_sistema_operacional text,
    p_solicitante_nome text,
    p_solicitante_telefone text,
    p_user_id uuid DEFAULT NULL,
    p_app_version text DEFAULT NULL
)
RETURNS TABLE (
    status text,
    is_approved boolean,
    motivo_bloqueio text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_status text;
    v_motivo text;
BEGIN
    -- Verifica se já existe
    SELECT d.status, d.motivo_bloqueio 
    INTO v_status, v_motivo
    FROM public.dispositivos_autorizados d
    WHERE d.device_id = p_device_id
    LIMIT 1;

    IF v_status IS NOT NULL THEN
        -- Atualiza última atividade e user_id (se fornecido) e app_version
        UPDATE public.dispositivos_autorizados
        SET ultima_atividade = now(),
            user_id = COALESCE(p_user_id, user_id),
            app_version = COALESCE(p_app_version, app_version)
        WHERE device_id = p_device_id;

        RETURN QUERY SELECT v_status, (v_status = 'aprovado'), v_motivo;
    ELSE
        -- Insere novo como pendente
        INSERT INTO public.dispositivos_autorizados (
            device_id,
            device_model,
            sistema_operacional,
            solicitante_nome,
            solicitante_telefone,
            status,
            user_id,
            app_version
        ) VALUES (
            p_device_id,
            p_device_model,
            p_sistema_operacional,
            p_solicitante_nome,
            p_solicitante_telefone,
            'pendente',
            p_user_id,
            p_app_version
        );

        RETURN QUERY SELECT 'pendente'::text, false, NULL::text;
    END IF;
END;
$$;

-- Atualiza a função listar_dispositivos_master para retornar app_version
DROP FUNCTION IF EXISTS public.listar_dispositivos_master();
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
    ultima_atividade TIMESTAMPTZ,
    app_version TEXT
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
        d.ultima_atividade,
        d.app_version
    FROM public.dispositivos_autorizados d
    ORDER BY d.created_at DESC;
END;
$$;
