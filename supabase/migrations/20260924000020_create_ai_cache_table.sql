-- Criação da tabela de cache da IA para fichas técnicas de veículos
CREATE TABLE IF NOT EXISTS public.vehicle_ai_specs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    year INTEGER NOT NULL,
    version TEXT,
    fuel TEXT,
    engine TEXT,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.vehicle_ai_specs ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "Permitir leitura pública ou para autenticados"
    ON public.vehicle_ai_specs FOR SELECT
    USING (true);

-- Apenas funções administrativas (Edge Functions com Service Role) podem inserir,
-- mas podemos garantir inserção também se necessário
CREATE POLICY "Permitir inserção por todos"
    ON public.vehicle_ai_specs FOR INSERT
    WITH CHECK (true);

-- Índices para otimizar a busca no cache
CREATE INDEX IF NOT EXISTS idx_vehicle_ai_specs_lookup 
    ON public.vehicle_ai_specs (brand, model, year);
