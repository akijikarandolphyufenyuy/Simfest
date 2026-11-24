-- ============================================================
-- SplitSure – Migration 011: the witness confirms the agreement too
--
-- When an agreement with a witness e-mail is sent for review:
--   • the witness is linked to an existing account with that e-mail (in-app + push
--     notification) and can confirm or decline from the agreement screen;
--   • the `agreement-emails` Edge Function also e-mails the witness (account or not)
--     a one-time "Confirm as witness" link (token hash in agreement_witness_tokens);
--   • the agreement only becomes 'accepted' once every required collaborator
--     accepted AND the witness confirmed. A witness who declines marks it 'declined'.
-- Witness answers are stamped with a signature code like collaborators'.
-- Safe to re-run.
-- ============================================================

alter table public.agreements add column if not exists witness_user_id uuid references auth.users(id) on delete set null;
alter table public.agreements add column if not exists witness_invited_version int;
alter table public.agreements add column if not exists witness_emailed_version int;
alter table public.agreements add column if not exists witness_response text;
alter table public.agreements add column if not exists witness_note text;
alter table public.agreements add column if not exists witness_responded_at timestamptz;
alter table public.agreements add column if not exists witness_signature_code text;
alter table public.agreements add column if not exists witness_signed_via text;
alter table public.agreements drop constraint if exists agreements_witness_response_check;
alter table public.agreements add constraint agreements_witness_response_check
  check (witness_response is null or witness_response in ('confirmed', 'declined'));

create table if not exists public.agreement_witness_tokens (
  token_hash   text primary key,               -- sha256 hex of the token mailed out
  agreement_id uuid not null references public.agreements(id) on delete cascade,
  version      int  not null,
  email        text not null,
  expires_at   timestamptz not null default now() + interval '30 days',
  used_at      timestamptz,
  created_at   timestamptz not null default now()
);
create index if not exists agreement_witness_tokens_agreement_idx on public.agreement_witness_tokens (agreement_id);
alter table public.agreement_witness_tokens enable row level security;
-- No policies: only the service role (Edge Function) reads or writes this table.

-- The witness can read the agreement (and its lines, versions, responses).
create or replace function public.is_agreement_party(p_agreement uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $function$
  select exists (select 1 from agreements where id = p_agreement and user_id = auth.uid())
      or exists (
        select 1 from agreement_splits s
         where s.agreement_id = p_agreement
           and (s.user_id = auth.uid()
                or (s.collaborator_email is not null
                    and lower(s.collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))))
      )
      or exists (
        select 1 from agreements a
         where a.id = p_agreement
           and (a.witness_user_id = auth.uid()
                or (a.witness_email is not null
                    and lower(trim(a.witness_email)) = lower(coalesce(auth.jwt()->>'email', ''))))
      );
$function$;

-- Witness answers can only be written by the RPCs below (the owner can't forge them).
create or replace function public._guard_witness_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_setting('splitsure.rpc', true) is distinct from 'on' then
    if tg_op = 'INSERT' then
      new.witness_user_id := null; new.witness_invited_version := null;
      new.witness_response := null; new.witness_note := null; new.witness_responded_at := null;
      new.witness_signature_code := null; new.witness_signed_via := null;
    else
      new.witness_user_id := old.witness_user_id;
      new.witness_invited_version := old.witness_invited_version;
      new.witness_response := old.witness_response;
      new.witness_note := old.witness_note;
      new.witness_responded_at := old.witness_responded_at;
      new.witness_signature_code := old.witness_signature_code;
      new.witness_signed_via := old.witness_signed_via;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists agreements_guard_witness on public.agreements;
create trigger agreements_guard_witness before insert or update on public.agreements
  for each row execute function public._guard_witness_columns();

-- Overall status from the collaborator lines and (when invited for this version) the witness.
create or replace function public._agreement_status(p_agreement uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
    when exists (select 1 from agreement_splits where agreement_id = a.id and response = 'declined')
      or (a.witness_invited_version = a.version and a.witness_response = 'declined') then 'declined'
    when exists (select 1 from agreement_splits where agreement_id = a.id and response = 'changes_requested')
      then 'changes_requested'
    when not exists (select 1 from agreement_splits where agreement_id = a.id and is_required
                       and coalesce(response, '') <> 'accepted')
     and (a.witness_invited_version is distinct from a.version or a.witness_response = 'confirmed')
      then 'accepted'
    else 'pending'
  end
  from agreements a where a.id = p_agreement;
$$;
revoke all on function public._agreement_status(uuid) from public, anon, authenticated;

-- Saves the new status and sends the "fully accepted" notifications.
create or replace function public._set_agreement_status(p_agreement uuid)
returns text
language plpgsql
security definer
set search_path = public
as $function$
declare a agreements; v_status text; v_now timestamptz := now();
begin
  v_status := _agreement_status(p_agreement);
  update agreements
     set status = v_status, updated_at = v_now,
         finalized_at = case when v_status = 'accepted' then v_now else null end
   where id = p_agreement
   returning * into a;
  if v_status = 'accepted' then
    perform notify_user(a.user_id, 'agreement_fully_accepted', 'agreement', a.id,
      jsonb_build_object('song', a.song_title), a.song_title, null);
    perform notify_user(x.user_id, 'agreement_fully_accepted', 'agreement', a.id,
      jsonb_build_object('song', a.song_title), a.song_title, null)
      from agreement_splits x where x.agreement_id = a.id and x.user_id is not null and x.user_id <> a.user_id;
    if a.witness_user_id is not null and a.witness_user_id <> a.user_id
       and not exists (select 1 from agreement_splits x where x.agreement_id = a.id and x.user_id = a.witness_user_id) then
      perform notify_user(a.witness_user_id, 'agreement_fully_accepted', 'agreement', a.id,
        jsonb_build_object('song', a.song_title), a.song_title, null);
    end if;
  end if;
  return v_status;
end;
$function$;
revoke all on function public._set_agreement_status(uuid) from public, anon, authenticated;

-- Collaborator responses (same as 010, status now via _set_agreement_status).
create or replace function public._apply_agreement_response(
  p_split uuid, p_user uuid, p_response text, p_note text, p_via text)
returns text
language plpgsql
security definer
set search_path = public
as $function$
declare s agreement_splits; a agreements; v_now timestamptz := now(); v_code text;
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
  perform notify_user(a.user_id,
    case p_response when 'accepted' then 'agreement_accepted'
                    when 'declined' then 'agreement_declined'
                    else 'agreement_changes_requested' end,
    'agreement', a.id, jsonb_build_object('song', a.song_title, 'name', s.collaborator_name, 'note', p_note),
    a.song_title, s.collaborator_name);
  return _set_agreement_status(a.id);
end;
$function$;
revoke all on function public._apply_agreement_response(uuid, uuid, text, text, text) from public, anon, authenticated;
grant execute on function public._apply_agreement_response(uuid, uuid, text, text, text) to service_role;

-- Witness answer (app or e-mail). p_user is null for e-mail answers.
create or replace function public._apply_witness_response(
  p_agreement uuid, p_user uuid, p_response text, p_note text, p_via text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $function$
declare a agreements; v_now timestamptz := now(); v_code text; v_status text;
begin
  if p_response not in ('confirmed','declined') then raise exception 'Invalid response'; end if;
  select * into a from agreements where id = p_agreement for update;
  if a.id is null then raise exception 'Not found'; end if;
  if a.status not in ('pending','changes_requested') then raise exception 'This agreement is not open for responses.'; end if;
  if a.witness_invited_version is distinct from a.version then raise exception 'NOT_INVITED'; end if;
  perform set_config('splitsure.rpc', 'on', true);
  if p_response = 'confirmed' then
    v_code := (select 'SS-W' || substr(h, 1, 3) || '-' || substr(h, 4, 4) || '-' || substr(h, 8, 4)
                 from (select upper(encode(extensions.digest(
                         a.id::text || '|' || a.version || '|witness|' || lower(coalesce(a.witness_email, '')) || '|' ||
                         coalesce(a.witness_name, '') || '|' || extract(epoch from v_now)::text || '|' ||
                         encode(extensions.gen_random_bytes(8), 'hex'), 'sha256'), 'hex')) as h) x);
  end if;
  update agreements
     set witness_user_id = coalesce(p_user, witness_user_id),
         witness_response = p_response, witness_note = nullif(trim(p_note), ''), witness_responded_at = v_now,
         witness_signature_code = v_code,
         witness_signed_via = case when p_response = 'confirmed' then p_via else null end
   where id = a.id;
  perform notify_user(a.user_id,
    case p_response when 'confirmed' then 'agreement_witness_confirmed' else 'agreement_witness_declined' end,
    'agreement', a.id, jsonb_build_object('song', a.song_title, 'name', a.witness_name, 'note', p_note),
    a.song_title, a.witness_name);
  v_status := _set_agreement_status(a.id);
  return jsonb_build_object('status', v_status, 'signature_code', v_code, 'response', p_response);
end;
$function$;
revoke all on function public._apply_witness_response(uuid, uuid, text, text, text) from public, anon, authenticated;
grant execute on function public._apply_witness_response(uuid, uuid, text, text, text) to service_role;

-- In-app answer by the signed-in witness.
create or replace function public.respond_as_witness(p_agreement uuid, p_response text, p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare a agreements; v_email text;
begin
  if auth.uid() is null then raise exception 'Sign in first.'; end if;
  v_email := lower(coalesce(auth.jwt()->>'email', ''));
  select * into a from agreements where id = p_agreement;
  if a.id is null then raise exception 'Not found'; end if;
  if not (a.witness_user_id = auth.uid() or lower(trim(coalesce(a.witness_email, ''))) = v_email) then
    raise exception 'Only the witness can do this.';
  end if;
  return _apply_witness_response(p_agreement, auth.uid(), p_response, p_note, 'app');
end;
$function$;
revoke all on function public.respond_as_witness(uuid, text, text) from public, anon;
grant execute on function public.respond_as_witness(uuid, text, text) to authenticated;

-- E-mail answer (service role only; the Edge Function hashes the token first).
create or replace function public.respond_witness_via_token(p_token_hash text, p_response text default 'confirmed')
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare t agreement_witness_tokens; a agreements; r jsonb;
begin
  select * into t from agreement_witness_tokens where token_hash = p_token_hash for update;
  if t.token_hash is null then raise exception 'INVALID_LINK'; end if;
  select * into a from agreements where id = t.agreement_id;
  if a.witness_response is not null and a.witness_invited_version = t.version and a.version = t.version then
    return jsonb_build_object('status', a.status, 'signature_code', a.witness_signature_code,
                              'response', a.witness_response, 'already', true);
  end if;
  if t.used_at is not null then raise exception 'LINK_USED'; end if;
  if t.expires_at < now() then raise exception 'LINK_EXPIRED'; end if;
  if a.version <> t.version then raise exception 'NEWER_VERSION'; end if;
  if lower(trim(coalesce(a.witness_email, ''))) <> lower(t.email) then raise exception 'INVALID_LINK'; end if;
  r := _apply_witness_response(a.id, null, p_response, null, 'email');
  update agreement_witness_tokens set used_at = now() where token_hash = p_token_hash;
  return r || jsonb_build_object('already', false);
end;
$function$;
revoke all on function public.respond_witness_via_token(text, text) from public, anon, authenticated;
grant execute on function public.respond_witness_via_token(text, text) to service_role;

-- Sending for review now invites the witness too.
create or replace function public.send_agreement_for_review(p_agreement uuid, p_note text default null)
returns integer
language plpgsql
security definer
set search_path = public
as $function$
declare a agreements; v_total numeric; v_count int; s record; v_kind text; v_witness uuid;
begin
  select * into a from agreements where id = p_agreement for update;
  if a.id is null or a.user_id <> auth.uid() then raise exception 'Only the agreement creator can do this.'; end if;
  if a.status = 'accepted' then raise exception 'This agreement has already been accepted by all parties.'; end if;
  select coalesce(sum(split_percentage), 0), count(*) into v_total, v_count
    from agreement_splits where agreement_id = p_agreement;
  if v_count = 0 then raise exception 'Add at least one collaborator before sending.'; end if;
  if v_total <> 100 then raise exception 'Percentages must total exactly 100%% (currently %).', v_total; end if;
  perform set_config('splitsure.rpc', 'on', true);

  -- Link collaborator lines to accounts that already exist with that e-mail.
  update agreement_splits sp
     set user_id = u.id
    from auth.users u
   where sp.agreement_id = p_agreement
     and sp.user_id is null
     and sp.collaborator_email is not null
     and lower(u.email) = lower(trim(sp.collaborator_email));

  if a.status <> 'draft' then
    update agreements set version = version + 1 where id = p_agreement;
    v_kind := 'agreement_new_version';
  else
    v_kind := 'agreement_invited';
  end if;
  update agreement_splits set response = null, response_note = null, responded_at = null, accepted_at = null
   where agreement_id = p_agreement;

  -- The witness (if any) is invited for this version; linked to their account when one exists.
  select u.id into v_witness from auth.users u
   where a.witness_email is not null and lower(u.email) = lower(trim(a.witness_email)) limit 1;
  update agreements
     set status = 'pending', finalized_at = null, updated_at = now(),
         witness_user_id = v_witness,
         witness_invited_version = case when nullif(trim(coalesce(witness_email, '')), '') is not null
                                        then version else null end,
         witness_response = null, witness_note = null, witness_responded_at = null,
         witness_signature_code = null, witness_signed_via = null
   where id = p_agreement;
  perform _snapshot_agreement(p_agreement, p_note);
  select * into a from agreements where id = p_agreement;
  for s in select * from agreement_splits where agreement_id = p_agreement and user_id is not null and user_id <> auth.uid() loop
    perform notify_user(s.user_id, v_kind, 'agreement', p_agreement,
      jsonb_build_object('song', a.song_title, 'version', a.version),
      case when v_kind = 'agreement_invited' then 'New collaboration agreement' else 'Agreement updated' end,
      a.song_title);
  end loop;
  if a.witness_user_id is not null and a.witness_user_id <> auth.uid() then
    perform notify_user(a.witness_user_id, 'agreement_witness_invited', 'agreement', p_agreement,
      jsonb_build_object('song', a.song_title, 'version', a.version),
      'Witness an agreement', a.song_title);
  end if;
  return a.version;
end;
$function$;

notify pgrst, 'reload schema';
