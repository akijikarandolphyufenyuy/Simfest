-- ============================================================
-- SplitSure – Migration 014: Basic plan = 1 free agreement document, then 50 FCFA each
--
-- • Basic (free) accounts may create any number of agreements, projects,
--   collaborators and witnesses (the 1-agreement insert limit is lifted).
-- • The creator's FIRST agreement is free: PDF preview and final document.
-- • Every other agreement needs a one-time 50 FCFA payment (any party may pay)
--   before its PDF can be previewed or downloaded; payment can be made before
--   everyone has accepted. Pro users preview and download everything for free.
-- • agreement_document_access() tells the app which case applies.
-- Safe to re-run.
-- ============================================================

-- 1. Unlimited agreements on Basic (the per-document fee replaces the cap).
update public.plan_features set enabled = true, limit_value = null
 where plan_id = 'free' and feature_key = 'max_agreements';

-- 2. A document can also be unlocked for free (first agreement).
alter table public.agreement_documents drop constraint if exists agreement_documents_unlocked_via_check;
alter table public.agreement_documents add constraint agreement_documents_unlocked_via_check
  check (unlocked_via in ('pro', 'payment', 'free'));

-- The creator's first agreement (oldest one they still own).
create or replace function public.is_first_agreement(p_agreement uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from agreements a
     where a.id = p_agreement
       and a.id = (select b.id from agreements b where b.user_id = a.user_id order by b.created_at, b.id limit 1)
  );
$$;
revoke all on function public.is_first_agreement(uuid) from public, anon;
grant execute on function public.is_first_agreement(uuid) to authenticated;

-- 'unlocked' (paid / already unlocked) | 'free' (Pro or first agreement) | 'pay' (50 FCFA needed).
create or replace function public.agreement_document_access(p_agreement uuid)
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_agreement_party(p_agreement) then raise exception 'Not allowed.'; end if;
  if exists (select 1 from agreement_documents where agreement_id = p_agreement) then return 'unlocked'; end if;
  if public.is_pro(auth.uid()) or public.is_first_agreement(p_agreement) then return 'free'; end if;
  return 'pay';
end;
$$;
revoke all on function public.agreement_document_access(uuid) from public, anon;
grant execute on function public.agreement_document_access(uuid) to authenticated;

-- Final document for free cases (Pro, or the first agreement). Needs every party's acceptance.
create or replace function public.unlock_agreement_free(p_agreement uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_status text;
begin
  if not public.is_agreement_party(p_agreement) then raise exception 'Not allowed.'; end if;
  select status into v_status from agreements where id = p_agreement;
  if v_status <> 'accepted' then raise exception 'All parties must accept the agreement first.'; end if;
  if public.is_pro(auth.uid()) then
    insert into agreement_documents (agreement_id, unlocked_via, unlocked_by)
    values (p_agreement, 'pro', auth.uid()) on conflict (agreement_id) do nothing;
  elsif public.is_first_agreement(p_agreement) then
    insert into agreement_documents (agreement_id, unlocked_via, unlocked_by)
    values (p_agreement, 'free', auth.uid()) on conflict (agreement_id) do nothing;
  else
    raise exception 'PAYMENT_REQUIRED';
  end if;
end;
$$;
revoke all on function public.unlock_agreement_free(uuid) from public, anon;
grant execute on function public.unlock_agreement_free(uuid) to authenticated;

-- The final PDF is only stored once every party accepted (unlocking can now happen earlier).
create or replace function public.record_final_pdf(p_agreement uuid, p_path text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_agreement_party(p_agreement) then raise exception 'Not allowed.'; end if;
  if (select status from agreements where id = p_agreement) <> 'accepted' then
    raise exception 'All parties must accept the agreement first.';
  end if;
  update agreement_documents set pdf_path = p_path, generated_at = coalesce(generated_at, now())
   where agreement_id = p_agreement;
  if not found then raise exception 'PAYMENT_REQUIRED'; end if;
  perform set_config('splitsure.rpc', 'on', true);
  update agreements set pdf_path = p_path where id = p_agreement;
end;
$$;

notify pgrst, 'reload schema';
