-- ==============================================================================
-- MIGRATION: 20260917_relatorios_rpc.sql
-- DESCRIÇÃO: Índices de performance e otimização para o Módulo de Relatórios e Dashboard
-- ==============================================================================

-- 1. Índices compostos de alta performance para vistorias_cloud
CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_user_created 
    ON public.vistorias_cloud(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_user_status 
    ON public.vistorias_cloud(user_id, status);

CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_empresa_cnpj 
    ON public.vistorias_cloud(empresa_cnpj);

-- Índice GIN para consultas rápidas dentro de dados_completos (JSONB)
CREATE INDEX IF NOT EXISTS idx_vistorias_cloud_dados_completos_gin 
    ON public.vistorias_cloud USING GIN (dados_completos);

-- 2. Garantir serviços de vistoria na tabela service_prices para faturamento
INSERT INTO public.service_prices (service_code, name, price, active)
VALUES 
    ('VISTORIA_CAUTELAR_COMPLETA', 'Vistoria Cautelar Croqui + Avarias', 180.00, true),
    ('VISTORIA_CAUTELAR_CARRO', 'Vistoria Cautelar Carro', 150.00, true),
    ('VISTORIA_CAUTELAR_CAMINHAO', 'Vistoria Cautelar Caminhão', 250.00, true),
    ('VISTORIA_LOJISTA', 'Vistoria Lojista', 120.00, true),
    ('VISTORIA_ENTRADA', 'Vistoria de Entrada / Check', 80.00, true)
ON CONFLICT (service_code) DO NOTHING;

-- 3. Função RPC para agregação de estatísticas de relatório por empresa
CREATE OR REPLACE FUNCTION public.get_relatorio_metricas(
    p_empresa_id UUID,
    p_data_inicio TIMESTAMPTZ,
    p_data_fim TIMESTAMPTZ
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_vistorias BIGINT;
    v_concluidas BIGINT;
    v_pendentes BIGINT;
    v_total_faturado NUMERIC(12, 2);
    v_ticket_medio NUMERIC(12, 2);
    v_total_clientes BIGINT;
    v_result JSONB;
BEGIN
    -- Validação de isolamento: usuário só pode ver seus próprios dados, exceto master
    IF auth.uid() != p_empresa_id AND NOT public.is_master() THEN
        RAISE EXCEPTION 'Acesso negado: você só pode consultar os dados da sua própria empresa.';
    END IF;

    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE status ILIKE '%concluido%' OR status ILIKE '%aprovado%'),
        COUNT(*) FILTER (WHERE status ILIKE '%andamento%' OR status ILIKE '%pendente%')
    INTO 
        v_total_vistorias,
        v_concluidas,
        v_pendentes
    FROM public.vistorias_cloud
    WHERE user_id = p_empresa_id
      AND created_at >= p_data_inicio
      AND created_at <= p_data_fim;

    -- Montagem do objeto de resposta
    v_result := jsonb_build_object(
        'total_vistorias', COALESCE(v_total_vistorias, 0),
        'laudos_concluidos', COALESCE(v_concluidas, 0),
        'laudos_pendentes', COALESCE(v_pendentes, 0)
    );

    RETURN v_result;
END;
$$;
