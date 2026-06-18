-- ============================================================
-- SQL de Configuração - Vistoria Cautelar Completa Profissional
-- ============================================================

-- Tabela Central de Vistorias
CREATE TABLE IF NOT EXISTS public.vistorias_cautelares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Identificação e Consulta (Step 1 e 2)
  placa TEXT,
  chassi TEXT,
  motor TEXT,
  marca TEXT,
  modelo TEXT,
  ano_fabricacao TEXT,
  ano_modelo TEXT,
  cor TEXT,
  codigo_consulta INT,
  id_pesquisa_autocred TEXT,
  dados_consulta_json JSONB, -- Salva todos os retornos brutos (BIN, Leilão, etc)
  
  -- OCR e Validações (Step 4 e 5)
  chassi_ocr TEXT,
  chassi_status TEXT, -- Compatível, Divergente, Não Localizado
  motor_ocr TEXT,
  motor_status TEXT, -- Original, Divergente, Remarcado, Não Localizado
  
  -- Dados flexíveis das outras etapas salvos como JSONB estruturado
  -- (Vidros, Etiquetas, Estrutura, Lataria, Pneus, Segurança)
  dados_inspecao JSONB DEFAULT '{}'::jsonb,
  
  -- Conclusão (Step 12 e 13)
  observacoes_gerais TEXT,
  parecer_tecnico TEXT,
  status_final TEXT, -- Aprovado, Reprovado, etc.
  
  -- Metadados
  draft BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE public.vistorias_cautelares ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own vistorias_cautelares" ON public.vistorias_cautelares
  FOR ALL USING (auth.uid() = user_id);

-- Tabela de Fotos (Relacionamento 1 para N com Vistorias)
CREATE TABLE IF NOT EXISTS public.vistorias_fotos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vistoria_id UUID NOT NULL REFERENCES public.vistorias_cautelares(id) ON DELETE CASCADE,
  categoria TEXT NOT NULL, -- Ex: 'externa_frente', 'chassi', 'motor', 'pneu_de'
  storage_path TEXT NOT NULL,
  url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE public.vistorias_fotos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own vistorias_fotos" ON public.vistorias_fotos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.vistorias_cautelares 
      WHERE id = vistorias_fotos.vistoria_id AND user_id = auth.uid()
    )
  );

-- Inserir novo Bucket no Storage para as fotos
INSERT INTO storage.buckets (id, name, public) VALUES ('vistoria_fotos', 'vistoria_fotos', true) ON CONFLICT (id) DO NOTHING;

-- Políticas de Storage para o Bucket 'vistoria_fotos'
CREATE POLICY "Authenticated users can upload fotos"
ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'vistoria_fotos');

CREATE POLICY "Users can update own fotos"
ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'vistoria_fotos');

CREATE POLICY "Users can read all fotos"
ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'vistoria_fotos');

CREATE POLICY "Users can delete own fotos"
ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'vistoria_fotos');
