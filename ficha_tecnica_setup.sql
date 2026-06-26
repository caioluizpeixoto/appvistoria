create table if not exists vehicle_ai_specs (
  id uuid primary key default gen_random_uuid(),
  brand text not null,
  model text not null,
  year int not null,
  version text,
  fuel text,
  engine text,
  data jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_vehicle_ai_specs_lookup
on vehicle_ai_specs (brand, model, year, version, fuel, engine);
