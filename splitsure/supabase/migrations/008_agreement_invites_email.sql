-- ============================================================
-- SplitSure – Migration 008: review invitations reach every party
--
-- 1. When an agreement is sent for review, collaborator lines are matched by
--    e-mail to EXISTING accounts (before, they were only linked when someone
--    registered later), so people who already use SplitSure get the in-app /
--    push notification straight away.
-- 2. agreement_email_log: one row per (collaborator line, version) that the
--    `agreement-emails` Edge Function e-mailed, so retries never send twice.
-- Safe to re-run.
-- ============================================================

create or replace function public.send_agreement_for_review(p_agreement uuid, p_note text default null)
returns integer
language plpgsql
security definer
set search_path = public
as $function$
declare a agreements; v_total numeric; v_count int; s record; v_kind text;
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
  update agreements set status = 'pending', finalized_at = null, updated_at = now() where id = p_agreement;
  perform _snapshot_agreement(p_agreement, p_note);
  select * into a from agreements where id = p_agreement;
  for s in select * from agreement_splits where agreement_id = p_agreement and user_id is not null and user_id <> auth.uid() loop
    perform notify_user(s.user_id, v_kind, 'agreement', p_agreement,
      jsonb_build_object('song', a.song_title, 'version', a.version),
      case when v_kind = 'agreement_invited' then 'New collaboration agreement' else 'Agreement updated' end,
      a.song_title);
  end loop;
  return a.version;
end;
$function$;

create table if not exists public.agreement_email_log (
  id           uuid primary key default gen_random_uuid(),
  agreement_id uuid not null references public.agreements(id) on delete cascade,
  split_id     uuid not null references public.agreement_splits(id) on delete cascade,
  version      int  not null,
  email        text not null,
  status       text not null check (status in ('sent', 'failed')),
  provider_id  text,
  error        text,
  created_at   timestamptz not null default now(),
  unique (split_id, version)
);
create index if not exists agreement_email_log_agreement_idx on public.agreement_email_log (agreement_id);

alter table public.agreement_email_log enable row level security;
-- The agreement creator can see delivery status; only the Edge Function (service role) writes.
drop policy if exists "Owner reads email log" on public.agreement_email_log;
create policy "Owner reads email log" on public.agreement_email_log
  for select to authenticated
  using (exists (select 1 from public.agreements a where a.id = agreement_id and a.user_id = auth.uid()));

notify pgrst, 'reload schema';
