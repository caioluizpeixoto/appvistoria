-- ============================================================
-- AppVistoria — SQL de Configuração do Banco de Dados Supabase
-- ============================================================
-- Execute este script no SQL Editor do Supabase (supabase.com)
-- Project Settings > SQL Editor > New Query
-- ============================================================

-- 1. Habilitar extensão UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABELAS
-- ============================================================

-- Tabela de usuários (perfil público)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de veículos
CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  placa TEXT NOT NULL,
  chassi TEXT NOT NULL,
  modelo TEXT NOT NULL,
  marca TEXT NOT NULL,
  ano INT NOT NULL,
  cor TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de vistorias
CREATE TABLE IF NOT EXISTS public.inspections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  data TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'pendente' 
    CHECK (status IN ('pendente', 'emAndamento', 'concluida', 'cancelada')),
  observacoes TEXT,
  assinatura_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de itens do checklist
CREATE TABLE IF NOT EXISTS public.checklist_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inspection_id UUID NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE,
  categoria TEXT NOT NULL,
  item TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'naoAvaliado'
    CHECK (status IN ('aprovado', 'reprovado', 'observacao', 'naoAvaliado')),
  observacao TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de fotos
CREATE TABLE IF NOT EXISTS public.inspection_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inspection_id UUID NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  tipo TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de relatórios
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inspection_id UUID NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Policies: users
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Policies: vehicles
CREATE POLICY "Users can manage own vehicles" ON public.vehicles
  FOR ALL USING (auth.uid() = user_id);

-- Policies: inspections
CREATE POLICY "Users can manage own inspections" ON public.inspections
  FOR ALL USING (auth.uid() = user_id);

-- Policies: checklist_items
CREATE POLICY "Users can manage checklist from own inspections" ON public.checklist_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND i.user_id = auth.uid()
    )
  );

-- Policies: inspection_photos
CREATE POLICY "Users can manage photos from own inspections" ON public.inspection_photos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND i.user_id = auth.uid()
    )
  );

-- Policies: reports
CREATE POLICY "Users can manage reports from own inspections" ON public.reports
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.inspections i
      WHERE i.id = inspection_id AND i.user_id = auth.uid()
    )
  );

-- ============================================================
-- STORAGE BUCKET
-- ============================================================
-- Criar bucket para fotos de inspeção (execute separadamente no Dashboard > Storage)
-- Nome do bucket: inspection-photos
-- Visibility: Private

-- ============================================================
-- ÍNDICES (performance)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_vehicles_user_id ON public.vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_inspections_user_id ON public.inspections(user_id);
CREATE INDEX IF NOT EXISTS idx_inspections_vehicle_id ON public.inspections(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_checklist_inspection_id ON public.checklist_items(inspection_id);
CREATE INDEX IF NOT EXISTS idx_photos_inspection_id ON public.inspection_photos(inspection_id);
