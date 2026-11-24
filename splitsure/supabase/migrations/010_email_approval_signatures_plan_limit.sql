-- ============================================================
-- SplitSure – Migration 010
--
-- 1. Electronic signatures: every acceptance stamps the collaborator line with a
--    signature code (SS-XXXX-XXXX-XXXX, derived from the agreement, version,
--    party, share and time) and how it was signed ('app' or 'email'). The code
--    is printed on the agreement document as that party's signature.
-- 2. Approve from the e-mail: the `agreement-emails` Edge Function issues a
--    one-time approval token per (collaborator line, version), stores only its
--    SHA-256 hash here and mails the token to the collaborator's address. The
--    creator never sees it, so nobody else can sign on a collaborator's behalf.
--    respond_via_email_token() is callable by the service role only.
-- 3. Basic (free) plan: at most 1 agreement. Enforced by the insert policy.
-- Safe to re-run.
-- ============================================================

alter table public.agreement_splits add column if not exists signature_code text;
alter table public.agreement_splits add column if not exists signed_via text;
alter table public.agreement_responses alter column user_id drop not null;
alter table public.agreement_responses add column if not exists via text not null default 'app';
alter table public.agreement_responses add column if not exists signature_code text;

create table if not exists public.agreement_approval_tokens (
  token_hash text primary key,                -- sha256 hex of the token mailed out
  split_id   uuid not null references public.agreement_splits(id) on delete cascade,
  version    int  not null,
  email      text not null,
  expires_at timestamptz not null default now() + interval '30 days',
  used_at    timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists agreement_approval_tokens_split_idx on public.agreement_approval_tokens (split_id);
alter table public.agreement_approval_tokens enable row level security;
-- No policies: only the service role (Edge Function) reads or writes this table.

-- Signature code for a party's acceptance.
create or replace function public._signature_code(p_split uuid, p_at timestamptz)
returns text
language sql
volatile
security definer
set search_path = public, extensions
as $$
  select 'SS-' || substr(h, 1, 4) || '-' || substr(h, 5, 4) || '-' || substr(h, 9, 4)
    from (
      select upper(encode(extensions.digest(
               s.agreement_id::text || '|' || a.version || '|' || s.id || '|' ||
               coalesce(lower(s.collaborator_email), '') || '|' || s.collaborator_name || '|' ||
               s.split_percentage || '|' || extract(epoch from p_at)::text || '|' ||
               encode(extensions.gen_random_bytes(8), 'hex'),
             'sha256'), 'hex')) as h
        from agreement_splits s join agreements a on a.id = s.agreement_id
       where s.id = p_split
    ) x;
$$;
revoke all on function public._signature_code(uuid, timestamptz) from public, anon, authenticated;

-- Shared response logic (app and e-mail). p_user may be null for e-mail signers without an account.
create or replace function public._apply_agreement_response(
  p_split uuid, p_user uuid, p_response text, p_note text, p_via text)
returns text
language plpgsql
security definer
set search_path = public
as $function$
declare s agreement_splits; a agreements; v_new_status text; v_now timestamptz := now(); v_code text;
begin
  if p_response not in ('accepted','changes_requested','declined') then raise exception 'Invalid response'; end if;
  select * into s from agreement_splits where id = p_split for update;
  if s.id is null then raise exception 'Not found'; end if;
  select * into a from agreements where id = s.agreement_id for update;
  if a.status not in ('pending','changes_requested') then raise exception 'This agreement is not open for responses.'; end if;
  if p_response = 'changes_requested' and coalesce(trim(p_note), '') = '' then
    raise exception 'Please describe the changes you need.';
  end if;
  perform set_config('splitsure.rpc', 'on', true);
  if p_response = 'accepted' then v_code := _signature_code(p_split, v_now); end if;
  update agreement_splits
     set user_id = coalesce(p_user, user_id), response = p_response, response_note = nullif(trim(p_note), ''),
         responded_at = v_now,
         accepted_at = case when p_response = 'accepted' then v_now else null end,
         signature_code = v_code,
         signed_via = case when p_response = 'accepted' then p_via else null end
   where id = p_split;
  insert into agreement_responses (agreement_id, split_id, version, user_id, response, note, via, signature_code)
  values (a.id, p_split, a.version, coalesce(p_user, s.user_id), p_response, nullif(trim(p_note), ''), p_via, v_code);
  if exists (select 1 from agreement_splits where agreement_id = a.id and response = 'declined') then
    v_new_status := 'declined';
  elsif exists (select 1 from agreement_splits where agreement_id = a.id and response = 'changes_requested') then
    v_new_status := 'changes_requested';
  elsif not exists (select 1 from agreement_splits where agreement_id = a.id and is_required
                      and coalesce(response, '') <> 'accepted') then
    v_new_status := 'accepted';
  else
    v_new_status := 'pending';
  end if;
  update agreements
     set status = v_new_status, updated_at = v_now,
         finalized_at = case when v_new_status = 'accepted' then v_now else null end
   where id = a.id;
  perform notify_user(a.user_id,
    case p_response when 'accepted' then 'agreement_accepted'
                    when 'declined' then 'agreement_declined'
                    else 'agreement_changes_requested' end,
    'agreement', a.id, jsonb_build_object('song', a.song_title, 'name', s.collaborator_name, 'note', p_note),
    a.song_title, s.collaborator_name);
  if v_new_status = 'accepted' then
    perform notify_user(a.user_id, 'agreement_fully_accepted', 'agreement', a.id,
      jsonb_build_object('song', a.song_title), a.song_title, null);
    perform notify_user(x.user_id, 'agreement_fully_accepted', 'agreement', a.id,
      jsonb_build_object('song', a.song_title), a.song_title, null)
      from agreement_splits x where x.agreement_id = a.id and x.user_id is not null and x.user_id <> a.user_id;
  end if;
  return v_new_status;
end;
$function$;
revoke all on function public._apply_agreement_response(uuid, uuid, text, text, text) from public, anon, authenticated;

-- In-app response (signed-in collaborator).
create or replace function public.respond_to_agreement(p_split uuid, p_response text, p_note text default null)
returns text
language plpgsql
security definer
set search_path = public
as $function$
declare s agreement_splits; v_email text;
begin
  if auth.uid() is null then raise exception 'Sign in first.'; end if;
  v_email := lower(coalesce(auth.jwt()->>'email', ''));
  select * into s from agreement_splits where id = p_split;
  if s.id is null then raise exception 'Not found'; end if;
  if not (s.user_id = auth.uid() or (s.user_id is null and lower(coalesce(s.collaborator_email, '')) = v_email)) then
    raise exception 'You can only respond for yourself.';
  end if;
  return _apply_agreement_response(p_split, auth.uid(), p_response, p_note, 'app');
end;
$function$;

-- Approve from the e-mail (service role only; the Edge Function hashes the token first).
create or replace function public.respond_via_email_token(p_token_hash text, p_response text default 'accepted')
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare t agreement_approval_tokens; s agreement_splits; a agreements; v_status text;
begin
  select * into t from agreement_approval_tokens where token_hash = p_token_hash for update;
  if t.token_hash is null then raise exception 'INVALID_LINK'; end if;
  select * into s from agreement_splits where id = t.split_id;
  select * into a from agreements where id = s.agreement_id;
  if s.response = 'accepted' and s.signature_code is not null and a.version = t.version then
    return jsonb_build_object('status', a.status, 'signature_code', s.signature_code, 'already', true);
  end if;
  if t.used_at is not null then raise exception 'LINK_USED'; end if;
  if t.expires_at < now() then raise exception 'LINK_EXPIRED'; end if;
  if a.version <> t.version then raise exception 'NEWER_VERSION'; end if;
  if lower(coalesce(s.collaborator_email, '')) <> lower(t.email) then raise exception 'INVALID_LINK'; end if;
  v_status := _apply_agreement_response(s.id, null, p_response, null, 'email');
  update agreement_approval_tokens set used_at = now() where token_hash = p_token_hash;
  select * into s from agreement_splits where id = t.split_id;
  return jsonb_build_object('status', v_status, 'signature_code', s.signature_code, 'already', false);
end;
$function$;
revoke all on function public.respond_via_email_token(text, text) from public, anon, authenticated;
grant execute on function public.respond_via_email_token(text, text) to service_role;
grant execute on function public._apply_agreement_response(uuid, uuid, text, text, text) to service_role;
grant execute on function public._signature_code(uuid, timestamptz) to service_role;

-- A new version clears old signatures (send_agreement_for_review resets responses).
create or replace function public._clear_signatures_on_reset()
returns trigger
language plpgsql
as $$
begin
  if new.accepted_at is null and old.accepted_at is not null then
    new.signature_code := null;
    new.signed_via := null;
  end if;
  return new;
end;
$$;
drop trigger if exists splits_clear_signatures on public.agreement_splits;
create trigger splits_clear_signatures before update on public.agreement_splits
  for each row execute function public._clear_signatures_on_reset();

-- Nobody can forge a signature through a direct insert/update.
create or replace function public._guard_signature_columns()
returns trigger
language plpgsql
as $$
begin
  if current_setting('splitsure.rpc', true) is distinct from 'on' then
    if tg_op = 'INSERT' then
      new.signature_code := null;
      new.signed_via := null;
    elsif (new.signature_code is not null and new.signature_code is distinct from old.signature_code)
       or (new.signed_via is not null and new.signed_via is distinct from old.signed_via) then
      raise exception 'Signatures can only be set by accepting the agreement.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists splits_guard_signatures on public.agreement_splits;
create trigger splits_guard_signatures before insert or update on public.agreement_splits
  for each row execute function public._guard_signature_columns();

-- ── Basic plan: 1 agreement ─────────────────────────────────────────────────
update public.plan_features set enabled = true, limit_value = 1
 where plan_id = 'free' and feature_key = 'max_agreements';

create or replace function public.can_create_agreement()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.plan_limit('max_agreements') is null
      or (select count(*) from public.agreements where user_id = auth.uid()) < public.plan_limit('max_agreements');
$$;
grant execute on function public.can_create_agreement() to authenticated;

drop policy if exists "Owner inserts agreements" on public.agreements;
create policy "Owner inserts agreements" on public.agreements
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_create_agreement());

notify pgrst, 'reload schema';
