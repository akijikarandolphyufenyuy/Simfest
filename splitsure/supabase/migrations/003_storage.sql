-- ============================================================
-- SplitSure – Migration 003 (storage buckets & policies)
-- Run after 002. Kept separate because some projects don't let the
-- SQL editor manage storage.objects policies; if this fails, create the
-- buckets/policies in Dashboard → Storage instead (see SETUP.md).
-- ============================================================
-- ============================================================
-- STORAGE
-- ============================================================
insert into storage.buckets (id, name, public) values
  ('avatars','avatars',true), ('agreement-assets','agreement-assets',true),
  ('campaign-assets','campaign-assets',true), ('agreement-pdfs','agreement-pdfs',false)
on conflict (id) do nothing;

-- Agreement PDFs are private: path = <agreement_id>/v<version>.pdf, readable by the parties only.
drop policy if exists "Agreement PDF read"   on storage.objects;
drop policy if exists "Agreement PDF upload" on storage.objects;
drop policy if exists "Agreement PDF update" on storage.objects;
create policy "Agreement PDF read" on storage.objects for select
  using (bucket_id = 'agreement-pdfs' and public.is_agreement_party(((storage.foldername(name))[1])::uuid));
create policy "Agreement PDF upload" on storage.objects for insert
  with check (bucket_id = 'agreement-pdfs' and public.is_agreement_party(((storage.foldername(name))[1])::uuid));
create policy "Agreement PDF update" on storage.objects for update
  using (bucket_id = 'agreement-pdfs' and public.is_agreement_party(((storage.foldername(name))[1])::uuid));

-- Public-read buckets; writes only into the user's own folder (<uid>/...).
drop policy if exists "Public assets read"   on storage.objects;
drop policy if exists "Own folder upload"    on storage.objects;
drop policy if exists "Own folder update"    on storage.objects;
drop policy if exists "Own folder delete"    on storage.objects;
create policy "Public assets read" on storage.objects for select
  using (bucket_id in ('avatars','agreement-assets','campaign-assets'));
create policy "Own folder upload" on storage.objects for insert
  with check (bucket_id in ('avatars','agreement-assets','campaign-assets')
              and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Own folder update" on storage.objects for update
  using (bucket_id in ('avatars','agreement-assets','campaign-assets')
         and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Own folder delete" on storage.objects for delete
  using (bucket_id in ('avatars','agreement-assets','campaign-assets')
         and auth.uid()::text = (storage.foldername(name))[1]);

