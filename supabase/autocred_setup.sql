-- ============================================================
-- SQL de Configuração - Tabela de Histórico da AutoCredCar
-- ============================================================

-- Tabela de consultas AutoCredCar
CREATE TABLE IF NOT EXISTS public.autocred_consultas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vistoria_id UUID REFERENCES public.inspections(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  placa TEXT,
  chassi TEXT,
  motor TEXT,
  codigo_consulta INT NOT NULL,
  id_pesquisa_autocred TEXT,
  status TEXT NOT NULL DEFAULT 'pendente',
  retorno_bruto TEXT,
  dados_tratados JSONB,
  arquivo_pesquisa_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE public.autocred_consultas ENABLE ROW LEVEL SECURITY;

-- Policy: Usuários gerenciam suas próprias consultas
CREATE POLICY "Users can manage own autocred consultas" ON public.autocred_consultas
  FOR ALL USING (auth.uid() = user_id);

-- Índices (performance)
CREATE INDEX IF NOT EXISTS idx_autocred_user_id ON public.autocred_consultas(user_id);
CREATE INDEX IF NOT EXISTS idx_autocred_vistoria_id ON public.autocred_consultas(vistoria_id);
CREATE INDEX IF NOT EXISTS idx_autocred_placa ON public.autocred_consultas(placa);
