-- Tabela para salvar cache de ilustrações 3D de veículos geradas por IA (OpenAI gpt-image-2)
create table if not exists vehicle_ai_images (
  id uuid primary key default gen_random_uuid(),
  brand text not null,
  model text not null,
  year text not null,
  parts_hash text not null default 'CLEAN',
  image_base64 text not null,
  source text default 'openai-gpt-image-2',
  created_at timestamptz default now()
);

-- Índice para busca rápida de imagens no cache
create index if not exists idx_vehicle_ai_images_lookup
on vehicle_ai_images (brand, model, year, parts_hash);

-- Habilitar RLS e permitir leitura pública/anon para consulta rápida
alter table vehicle_ai_images enable row level security;

create policy "Permitir leitura anon e authenticated em vehicle_ai_images"
on vehicle_ai_images for select
using (true);

create policy "Permitir insercao anon e authenticated em vehicle_ai_images"
on vehicle_ai_images for insert
with check (true);
