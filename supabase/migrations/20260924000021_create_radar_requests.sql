CREATE TABLE IF NOT EXISTS public.radar_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key TEXT UNIQUE NOT NULL,
    vistoria_id UUID,
    user_id UUID NOT NULL,
    company_id UUID,
    produto TEXT NOT NULL,
    param TEXT NOT NULL,
    value TEXT NOT NULL,
    radar_token TEXT,
    status TEXT NOT NULL DEFAULT 'creating', -- creating, processing, completed, error, creation_unknown, failed_before_create
    raw_response JSONB,
    parsed_data JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Habilitar RLS
ALTER TABLE public.radar_requests ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
DROP POLICY IF EXISTS "Usuários podem ver suas próprias requisições" ON public.radar_requests;
CREATE POLICY "Usuários podem ver suas próprias requisições"
    ON public.radar_requests FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem criar requisições" ON public.radar_requests;
CREATE POLICY "Usuários podem criar requisições"
    ON public.radar_requests FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuários podem atualizar requisições" ON public.radar_requests;
CREATE POLICY "Usuários podem atualizar requisições"
    ON public.radar_requests FOR UPDATE
    USING (auth.uid() = user_id);

-- Index para buscas rápidas pelo token e idempotency_key
CREATE INDEX IF NOT EXISTS idx_radar_requests_token ON public.radar_requests(radar_token);
CREATE INDEX IF NOT EXISTS idx_radar_requests_idempotency ON public.radar_requests(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_radar_requests_vistoria ON public.radar_requests(vistoria_id);
