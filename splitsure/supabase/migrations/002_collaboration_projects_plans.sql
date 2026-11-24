-- ============================================================
-- SplitSure – Migration 002
-- Collaboration workflow, music projects, configurable plans,
-- localized notifications, private agreement PDFs, promo videos.
--
-- Run AFTER 001_initial_schema.sql in Supabase → SQL Editor.
-- Safe to re-run: every statement is idempotent.
-- ============================================================

create extension if not exists pgcrypto;

-- ── Owner column: some databases were created with "owner_id" instead of
--    "user_id". Rename it (data and existing policies are kept) so the app and
--    this migration use one name. Drop the old owner triggers: their code uses
--    the old name and a column default replaces them.
do $$
begin
  if exists (select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'agreements' and column_name = 'owner_id')
     and not exists (select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'agreements' and column_name = 'user_id') then
    alter table public.agreements rename column owner_id to user_id;
  end if;
  if exists (select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'campaigns' and column_name = 'owner_id')
     and not exists (select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'campaigns' and column_name = 'user_id') then
    alter table public.campaigns rename column owner_id to user_id;
  end if;
end $$;
drop trigger if exists set_agreement_owner_trigger on public.agreements;
drop trigger if exists set_campaign_owner_trigger on public.campaigns;

-- ── Owner columns default to the signed-in user ─────────────
alter table public.agreements alter column user_id set default auth.uid();
alter table public.campaigns  alter column user_id set default auth.uid();

-- ============================================================
-- PROFILES: e-mail (to match invited collaborators), language,
-- notification preferences
-- ============================================================
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists preferred_language text default 'en';
alter table public.profiles add column if not exists notification_prefs jsonb not null default '{}'::jsonb;

update public.profiles p set email = u.email
  from auth.users u where u.id = p.id and p.email is null;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, first_name, last_name, username, phone, country, email, preferred_language)
  values (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    nullif(new.raw_user_meta_data->>'username', ''),
    nullif(new.raw_user_meta_data->>'phone', ''),
    coalesce(new.raw_user_meta_data->>'country', 'Cameroon'),
    new.email,
    coalesce(new.raw_user_meta_data->>'preferred_language', 'en')
  )
  on conflict (id) do nothing;

  -- Link any agreement invitations sent to this e-mail before the user registered.
  perform set_config('splitsure.rpc', 'on', true);
  update public.agreement_splits
     set user_id = new.id
   where user_id is null and lower(collaborator_email) = lower(new.email);
  return new;
end;
$$;

-- Profiles stay private (own row only). Collaborator names live on agreement_splits.
drop policy if exists "Profiles readable by signed-in users" on public.profiles;

-- ============================================================
-- MUSIC PROJECTS
-- ============================================================
create table if not exists public.projects (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title          text not null,
  genre          text,
  description    text,
  cover_art_url  text,
  recording_date date,
  release_date   date,
  status         text not null default 'in_progress'
                   check (status in ('idea','in_progress','recorded','released')),
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);
alter table public.projects enable row level security;

alter table public.agreements add column if not exists project_id uuid references public.projects(id) on delete set null;
alter table public.campaigns  add column if not exists project_id uuid references public.projects(id) on delete set null;

-- ============================================================
-- AGREEMENTS: versioning, reference, scope, payment terms
-- ============================================================
alter table public.agreements add column if not exists version int not null default 1;
alter table public.agreements add column if not exists reference text;
alter table public.agreements add column if not exists scope_categories text[] not null default '{}';
alter table public.agreements add column if not exists payment_terms text;
alter table public.agreements add column if not exists finalized_at timestamptz;
alter table public.agreements add column if not exists pdf_path text;

update public.agreements set reference = 'SS-' || upper(substr(replace(id::text, '-', ''), 1, 8))
 where reference is null;
create unique index if not exists agreements_reference_key on public.agreements(reference);

create or replace function public.set_agreement_reference()
returns trigger language plpgsql as $$
begin
  if new.reference is null then
    new.reference := 'SS-' || upper(substr(replace(new.id::text, '-', ''), 1, 8));
  end if;
  return new;
end;
$$;
drop trigger if exists agreements_reference on public.agreements;
create trigger agreements_reference before insert on public.agreements
  for each row execute procedure public.set_agreement_reference();

-- Collaborator (split) columns
alter table public.agreement_splits add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.agreement_splits add column if not exists invite_token uuid not null default gen_random_uuid();
alter table public.agreement_splits add column if not exists response_note text;
alter table public.agreement_splits add column if not exists responded_at timestamptz;
alter table public.agreement_splits add column if not exists is_required boolean not null default true;
create unique index if not exists agreement_splits_invite_token_key on public.agreement_splits(invite_token);

-- Immutable version snapshots
create table if not exists public.agreement_versions (
  id           uuid primary key default gen_random_uuid(),
  agreement_id uuid not null references public.agreements(id) on delete cascade,
  version      int not null,
  snapshot     jsonb not null,
  change_note  text,
  created_by   uuid references auth.users(id),
  created_at   timestamptz default now(),
  unique (agreement_id, version)
);
alter table public.agreement_versions enable row level security;

-- Immutable response log (who answered what, on which version, when)
create table if not exists public.agreement_responses (
  id           uuid primary key default gen_random_uuid(),
  agreement_id uuid not null references public.agreements(id) on delete cascade,
  split_id     uuid not null references public.agreement_splits(id) on delete cascade,
  version      int not null,
  user_id      uuid not null references auth.users(id),
  response     text not null check (response in ('accepted','changes_requested','declined')),
  note         text,
  created_at   timestamptz default now()
);
alter table public.agreement_responses enable row level security;

-- ── Access helpers (security definer: bypass RLS recursion) ─
create or replace function public.is_agreement_owner(p_agreement uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from agreements where id = p_agreement and user_id = auth.uid());
$$;

create or replace function public.is_agreement_party(p_agreement uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from agreements where id = p_agreement and user_id = auth.uid())
      or exists (
        select 1 from agreement_splits s
         where s.agreement_id = p_agreement
           and (s.user_id = auth.uid()
                or (s.collaborator_email is not null
                    and lower(s.collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))))
      );
$$;

-- ── RLS: agreements ─────────────────────────────────────────
drop policy if exists "Users manage own agreements" on public.agreements;
drop policy if exists "Owner agreements"            on public.agreements;
drop policy if exists "Parties read agreements"    on public.agreements;
drop policy if exists "Owner inserts agreements"   on public.agreements;
drop policy if exists "Owner updates agreements"   on public.agreements;
drop policy if exists "Owner deletes agreements"   on public.agreements;
-- Owner check first: during INSERT ... RETURNING the helper function cannot see the new row yet.
create policy "Parties read agreements"  on public.agreements for select
  using (user_id = auth.uid() or public.is_agreement_party(id));
create policy "Owner inserts agreements" on public.agreements for insert with check (user_id = auth.uid());
create policy "Owner updates agreements" on public.agreements for update using (user_id = auth.uid());
create policy "Owner deletes agreements" on public.agreements for delete
  using (user_id = auth.uid() and status in ('draft','declined'));

-- ── RLS: splits (collaborators answer through respond_to_agreement) ─
drop policy if exists "Users manage splits of own agreements" on public.agreement_splits;
drop policy if exists "Owner agreement splits" on public.agreement_splits;
drop policy if exists "Parties read splits"   on public.agreement_splits;
drop policy if exists "Owner writes splits"   on public.agreement_splits;
create policy "Parties read splits" on public.agreement_splits for select using (public.is_agreement_party(agreement_id));
create policy "Owner writes splits" on public.agreement_splits for all
  using (public.is_agreement_owner(agreement_id)) with check (public.is_agreement_owner(agreement_id));

drop policy if exists "Parties read versions"  on public.agreement_versions;
create policy "Parties read versions" on public.agreement_versions for select using (public.is_agreement_party(agreement_id));
drop policy if exists "Parties read responses" on public.agreement_responses;
create policy "Parties read responses" on public.agreement_responses for select using (public.is_agreement_party(agreement_id));

-- ── RLS: projects (owner, plus collaborators on its agreements) ─
drop policy if exists "Owner manages projects" on public.projects;
drop policy if exists "Parties read projects"  on public.projects;
create policy "Owner manages projects" on public.projects for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Parties read projects" on public.projects for select using (
  exists (select 1 from public.agreements a where a.project_id = projects.id and public.is_agreement_party(a.id))
);

-- ── Accepted agreements cannot be silently overwritten ──────
create or replace function public.protect_accepted_agreement()
returns trigger language plpgsql as $$
begin
  -- Status, version and finalization only move through the RPCs below
  -- (a creator can never mark an agreement "accepted" on their own).
  if current_setting('splitsure.rpc', true) is distinct from 'on'
     and (new.status is distinct from old.status or new.version is distinct from old.version
          or new.finalized_at is distinct from old.finalized_at) then
    raise exception 'Agreement status can only change through the review workflow.';
  end if;
  if old.status = 'accepted' and current_setting('splitsure.rpc', true) is distinct from 'on' then
    -- only the stored PDF location may change once everyone has accepted
    if (to_jsonb(new) - 'pdf_url' - 'pdf_path' - 'updated_at')
       is distinct from (to_jsonb(old) - 'pdf_url' - 'pdf_path' - 'updated_at') then
      raise exception 'Accepted agreements cannot be modified. Create a new agreement instead.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists agreements_protect_accepted on public.agreements;
create trigger agreements_protect_accepted before update on public.agreements
  for each row execute procedure public.protect_accepted_agreement();

create or replace function public.protect_accepted_splits()
returns trigger language plpgsql as $$
declare v_status text;
begin
  select status into v_status from public.agreements
   where id = case when tg_op = 'DELETE' then old.agreement_id else new.agreement_id end;
  if current_setting('splitsure.rpc', true) is distinct from 'on' then
    if v_status = 'accepted' then
      raise exception 'Collaborators of an accepted agreement cannot be changed.';
    end if;
    -- Responses are recorded only by respond_to_agreement (never written by the creator).
    if tg_op = 'INSERT' and (new.response is not null or new.accepted_at is not null or new.responded_at is not null) then
      raise exception 'Responses are recorded by each collaborator.';
    end if;
    if tg_op = 'UPDATE' and (new.response is distinct from old.response
        or new.accepted_at is distinct from old.accepted_at
        or new.responded_at is distinct from old.responded_at
        or new.user_id is distinct from old.user_id
        or new.invite_token is distinct from old.invite_token) then
      raise exception 'Responses are recorded by each collaborator.';
    end if;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;
drop trigger if exists splits_protect_accepted on public.agreement_splits;
create trigger splits_protect_accepted before insert or update or delete on public.agreement_splits
  for each row execute procedure public.protect_accepted_splits();

-- ============================================================
-- NOTIFICATIONS: localizable kind + params; inserts only from
-- trusted (security definer) code
-- ============================================================
alter table public.notifications add column if not exists kind text;
alter table public.notifications add column if not exists params jsonb not null default '{}'::jsonb;
drop policy if exists "Service role can insert notifications" on public.notifications;
drop policy if exists "Users delete own notifications" on public.notifications;
create policy "Users delete own notifications" on public.notifications for delete using (auth.uid() = user_id);

create or replace function public.notify_user(
  p_user uuid, p_kind text, p_type text, p_related uuid, p_params jsonb, p_title text, p_body text)
returns void language plpgsql security definer set search_path = public as $$
declare v_prefs jsonb;
begin
  if p_user is null then return; end if;
  select notification_prefs into v_prefs from profiles where id = p_user;
  -- users can switch off a category (agreement / campaign / subscription) in Settings
  if coalesce((v_prefs->>p_type)::boolean, true) = false then return; end if;
  insert into notifications (user_id, title, body, type, related_id, kind, params)
  values (p_user, p_title, p_body, p_type, p_related, p_kind, coalesce(p_params, '{}'::jsonb));
end;
$$;
revoke all on function public.notify_user(uuid, text, text, uuid, jsonb, text, text) from public, anon, authenticated;

-- ============================================================
-- COLLABORATION RPCs
-- ============================================================

-- Snapshot the agreement + collaborators into agreement_versions.
create or replace function public._snapshot_agreement(p_agreement uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare a agreements; v_snapshot jsonb;
begin
  select * into a from agreements where id = p_agreement;
  select to_jsonb(a) - 'pdf_url' - 'pdf_path'
         || jsonb_build_object('splits', coalesce((
              select jsonb_agg(jsonb_build_object(
                'collaborator_name', s.collaborator_name, 'collaborator_email', s.collaborator_email,
                'role', s.role, 'contribution_description', s.contribution_description,
                'split_percentage', s.split_percentage) order by s.created_at)
                from agreement_splits s where s.agreement_id = p_agreement), '[]'::jsonb))
    into v_snapshot;
  insert into agreement_versions (agreement_id, version, snapshot, change_note, created_by)
  values (p_agreement, a.version, v_snapshot, p_note, auth.uid())
  on conflict (agreement_id, version) do update set snapshot = excluded.snapshot, change_note = excluded.change_note;
end;
$$;

-- Owner sends a draft (or an edited agreement) to collaborators.
-- First send = version 1; later sends create a new version and reset all answers.
create or replace function public.send_agreement_for_review(p_agreement uuid, p_note text default null)
returns int language plpgsql security definer set search_path = public as $$
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
$$;

-- A collaborator answers for their own line (matched by account or invited e-mail).
create or replace function public.respond_to_agreement(p_split uuid, p_response text, p_note text default null)
returns text language plpgsql security definer set search_path = public as $$
declare s agreement_splits; a agreements; v_email text; v_new_status text; v_name text;
begin
  if p_response not in ('accepted','changes_requested','declined') then raise exception 'Invalid response'; end if;
  v_email := lower(coalesce(auth.jwt()->>'email', ''));
  select * into s from agreement_splits where id = p_split for update;
  if s.id is null then raise exception 'Not found'; end if;
  if not (s.user_id = auth.uid() or (s.user_id is null and lower(coalesce(s.collaborator_email, '')) = v_email)) then
    raise exception 'You can only respond for yourself.';
  end if;
  select * into a from agreements where id = s.agreement_id for update;
  if a.status not in ('pending','changes_requested') then raise exception 'This agreement is not open for responses.'; end if;
  if p_response <> 'accepted' and coalesce(trim(p_note), '') = '' and p_response = 'changes_requested' then
    raise exception 'Please describe the changes you need.';
  end if;

  perform set_config('splitsure.rpc', 'on', true);
  update agreement_splits
     set user_id = auth.uid(), response = p_response, response_note = nullif(trim(p_note), ''),
         responded_at = now(), accepted_at = case when p_response = 'accepted' then now() else null end
   where id = p_split;
  insert into agreement_responses (agreement_id, split_id, version, user_id, response, note)
  values (a.id, p_split, a.version, auth.uid(), p_response, nullif(trim(p_note), ''));

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
     set status = v_new_status, updated_at = now(),
         finalized_at = case when v_new_status = 'accepted' then now() else null end
   where id = a.id;

  v_name := s.collaborator_name;
  perform notify_user(a.user_id,
    case p_response when 'accepted' then 'agreement_accepted'
                    when 'declined' then 'agreement_declined'
                    else 'agreement_changes_requested' end,
    'agreement', a.id, jsonb_build_object('song', a.song_title, 'name', v_name, 'note', p_note),
    a.song_title, v_name);
  if v_new_status = 'accepted' then
    perform notify_user(a.user_id, 'agreement_fully_accepted', 'agreement', a.id,
      jsonb_build_object('song', a.song_title), a.song_title, null);
    -- tell every linked collaborator too
    perform notify_user(x.user_id, 'agreement_fully_accepted', 'agreement', a.id,
      jsonb_build_object('song', a.song_title), a.song_title, null)
      from agreement_splits x where x.agreement_id = a.id and x.user_id is not null and x.user_id <> a.user_id;
  end if;
  return v_new_status;
end;
$$;

-- Secure invitation link: /invite/<token>. Links the signed-in user to that collaborator line.
create or replace function public.claim_agreement_invite(p_token uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare s agreement_splits;
begin
  if auth.uid() is null then raise exception 'Sign in first.'; end if;
  select * into s from agreement_splits where invite_token = p_token;
  if s.id is null then raise exception 'This invitation link is invalid.'; end if;
  if s.user_id is not null and s.user_id <> auth.uid() then
    raise exception 'This invitation has already been claimed by another account.';
  end if;
  perform set_config('splitsure.rpc', 'on', true);
  update agreement_splits set user_id = auth.uid() where id = s.id;
  return s.agreement_id;
end;
$$;

grant execute on function public.send_agreement_for_review(uuid, text) to authenticated;
grant execute on function public.respond_to_agreement(uuid, text, text) to authenticated;
grant execute on function public.claim_agreement_invite(uuid) to authenticated;

-- ============================================================
-- PLANS & FEATURE ACCESS (admin-configurable, prices in FCFA)
-- ============================================================
create table if not exists public.plans (
  id            text primary key,
  price_fcfa    integer not null,
  duration_days integer,              -- null = no expiry (free)
  sort_order    integer not null default 0,
  is_active     boolean not null default true
);
insert into public.plans (id, price_fcfa, duration_days, sort_order) values
  ('free', 0, null, 0), ('monthly', 1000, 30, 1), ('quarterly', 2500, 90, 2), ('annual', 5000, 365, 3)
on conflict (id) do update set price_fcfa = excluded.price_fcfa, duration_days = excluded.duration_days;

-- feature_key examples: max_agreements, max_campaigns, max_projects, promo_video, pdf_export
-- limit_value null = unlimited. Edit these rows to change what each plan allows.
create table if not exists public.plan_features (
  plan_id     text references public.plans(id) on delete cascade,
  feature_key text not null,
  enabled     boolean not null default true,
  limit_value integer,
  primary key (plan_id, feature_key)
);
insert into public.plan_features (plan_id, feature_key, enabled, limit_value) values
  ('free','max_agreements',true,3), ('free','max_campaigns',true,3), ('free','max_projects',true,3),
  ('free','promo_video',true,null), ('free','pdf_export',true,null),
  ('monthly','max_agreements',true,null), ('monthly','max_campaigns',true,null), ('monthly','max_projects',true,null),
  ('monthly','promo_video',true,null), ('monthly','pdf_export',true,null),
  ('quarterly','max_agreements',true,null), ('quarterly','max_campaigns',true,null), ('quarterly','max_projects',true,null),
  ('quarterly','promo_video',true,null), ('quarterly','pdf_export',true,null),
  ('annual','max_agreements',true,null), ('annual','max_campaigns',true,null), ('annual','max_projects',true,null),
  ('annual','promo_video',true,null), ('annual','pdf_export',true,null)
on conflict do nothing;

alter table public.plans enable row level security;
alter table public.plan_features enable row level security;
drop policy if exists "Plans readable" on public.plans;
create policy "Plans readable" on public.plans for select using (true);
drop policy if exists "Plan features readable" on public.plan_features;
create policy "Plan features readable" on public.plan_features for select using (true);

alter table public.subscriptions add column if not exists payment_status text not null default 'demo'
  check (payment_status in ('demo','pending','paid','failed','refunded'));
alter table public.subscriptions add column if not exists payment_provider text;

-- Users may not mark their own subscriptions as paid: only demo rows from the client.
drop policy if exists "Users insert own subscriptions" on public.subscriptions;
drop policy if exists "Users update own subscriptions" on public.subscriptions;
drop policy if exists "Users manage own subscriptions" on public.subscriptions;
drop policy if exists "Users view own subscriptions" on public.subscriptions;
drop policy if exists "Users insert own demo subscriptions" on public.subscriptions;
create policy "Users view own subscriptions" on public.subscriptions for select using (auth.uid() = user_id);
create policy "Users insert own demo subscriptions" on public.subscriptions for insert
  with check (auth.uid() = user_id and status = 'demo' and payment_status = 'demo');

-- Expire subscriptions and warn 3 days ahead. Schedule daily with pg_cron:
--   select cron.schedule('splitsure-expiry', '0 7 * * *', 'select public.process_subscription_expiry()');
create or replace function public.process_subscription_expiry()
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select * from subscriptions
            where status in ('active','demo') and expires_at is not null
              and expires_at between now() + interval '2 days' and now() + interval '3 days' loop
    perform notify_user(r.user_id, 'subscription_expiring', 'subscription', r.id,
      jsonb_build_object('plan', r.plan, 'date', to_char(r.expires_at, 'YYYY-MM-DD')),
      'Subscription expiring soon', r.plan);
  end loop;
  for r in update subscriptions set status = 'expired'
            where status in ('active','demo') and expires_at is not null and expires_at < now()
            returning * loop
    perform notify_user(r.user_id, 'subscription_expired', 'subscription', r.id,
      jsonb_build_object('plan', r.plan), 'Subscription expired', r.plan);
  end loop;
end;
$$;

-- ============================================================
-- CAMPAIGNS: artist name, generated video
-- ============================================================
alter table public.campaigns add column if not exists artist_name text;
alter table public.campaigns add column if not exists video_url text;
alter table public.campaigns add column if not exists video_template text;

create or replace function public.notify_campaign_completed()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'completed' and old.status is distinct from 'completed' then
    perform notify_user(new.user_id, 'campaign_completed', 'campaign', new.id,
      jsonb_build_object('campaign', coalesce(new.campaign_name, new.song_title)),
      'Campaign completed', coalesce(new.campaign_name, new.song_title));
  end if;
  return new;
end;
$$;
drop trigger if exists campaigns_completed on public.campaigns;
create trigger campaigns_completed after update on public.campaigns
  for each row execute procedure public.notify_campaign_completed();

-- ============================================================
-- FCM TOKENS (browser push tokens, one row per device)
-- ============================================================
create table if not exists public.fcm_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  token      text not null unique,
  platform   text default 'web',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.fcm_tokens enable row level security;
drop policy if exists "Users manage own FCM tokens" on public.fcm_tokens;
create policy "Users manage own FCM tokens" on public.fcm_tokens
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- Realtime: live notification badge
-- ============================================================
do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when others then null; end $$;
