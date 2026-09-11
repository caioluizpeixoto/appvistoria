-- Migração para criar o bucket laudos-pdf que estava faltando e estava causando erro 404 no QRCode
insert into storage.buckets (id, name, public)
values ('laudos-pdf', 'laudos-pdf', true)
on conflict (id) do nothing;

create policy "Public Access to Laudos PDF"
on storage.objects for select
to public
using ( bucket_id = 'laudos-pdf' );

create policy "Authenticated uploads to Laudos PDF"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'laudos-pdf' );

create policy "Authenticated updates to Laudos PDF"
on storage.objects for update
to authenticated
using ( bucket_id = 'laudos-pdf' );

create policy "Anon uploads to Laudos PDF"
on storage.objects for insert
to anon
with check ( bucket_id = 'laudos-pdf' );

create policy "Anon updates to Laudos PDF"
on storage.objects for update
to anon
using ( bucket_id = 'laudos-pdf' );
