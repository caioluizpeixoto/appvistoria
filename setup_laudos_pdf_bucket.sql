-- 1. Criar o bucket 'laudos-pdf' com acesso público
insert into storage.buckets (id, name, public)
values ('laudos-pdf', 'laudos-pdf', true)
on conflict (id) do nothing;

-- 2. Permitir que qualquer pessoa acesse e baixe os PDFs (necessário para o QR Code funcionar)
create policy "Leitura Publica Laudos PDF"
  on storage.objects for select
  using ( bucket_id = 'laudos-pdf' );

-- 3. Permitir o upload e atualização de laudos no bucket (Qualquer usuário autenticado)
create policy "Upload Laudos PDF"
  on storage.objects for insert
  with check ( bucket_id = 'laudos-pdf' );

create policy "Update Laudos PDF"
  on storage.objects for update
  using ( bucket_id = 'laudos-pdf' );
