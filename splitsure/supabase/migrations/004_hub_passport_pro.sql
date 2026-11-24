-- ============================================================
-- SplitSure – Migration 004
-- Free/Pro plans & entitlements, payments (MeSomb via Edge Function),
-- paid final agreement documents, Music Passport, Opportunity Hub,
-- applications, DealFlow workspaces, Reach Pro-only.
-- Run after 002 and 003. Idempotent.
-- ============================================================

-- ── Plans: Free + Pro (100 FCFA, one-time; set duration_days for recurring later)
update public.plans set is_active = false where id in ('monthly','quarterly','annual');
insert into public.plans (id, price_fcfa, duration_days, sort_order, is_active)
values ('free', 0, null, 0, true), ('pro', 100, null, 1, true)
on conflict (id) do update set price_fcfa = excluded.price_fcfa, duration_days = excluded.duration_days,
  sort_order = excluded.sort_order, is_active = true;

-- feature_key → (enabled, limit). Edit these rows to change what each plan allows.
insert into public.plan_features (plan_id, feature_key, enabled, limit_value) values
  ('free','max_projects',true,3), ('free','max_agreements',true,null), ('free','opportunity_posts',true,1),
  ('free','reach',false,null), ('free','max_campaigns',false,0), ('free','promo_video',false,null),
  ('free','pdf_export',true,null), ('free','free_agreement_generation',false,null),
  ('pro','max_projects',true,null), ('pro','max_agreements',true,null), ('pro','opportunity_posts',true,null),
  ('pro','reach',true,null), ('pro','max_campaigns',true,null), ('pro','promo_video',true,null),
  ('pro','pdf_export',true,null), ('pro','free_agreement_generation',true,null)
on conflict (plan_id, feature_key) do update set enabled = excluded.enabled, limit_value = excluded.limit_value;

-- ============================================================
-- ENTITLEMENTS (one row per user; read-only for clients)
-- ============================================================
create table if not exists public.user_entitlements (
  user_id             uuid primary key references auth.users(id) on delete cascade,
  plan_type           text not null default 'free' check (plan_type in ('free','pro')),
  subscription_status text not null default 'active' check (subscription_status in ('active','inactive','expired')),
  pro_activated_at    timestamptz,
  pro_expires_at      timestamptz,
  payment_status      text not null default 'none' check (payment_status in ('none','pending','paid','failed')),
  free_posts_used     int not null default 0,
  plan_chosen_at      timestamptz,
  updated_at          timestamptz default now()
);
alter table public.user_entitlements enable row level security;
drop policy if exists "Users read own entitlements" on public.user_entitlements;
create policy "Users read own entitlements" on public.user_entitlements for select using (auth.uid() = user_id);
insert into public.user_entitlements (user_id) select id from auth.users on conflict do nothing;

create or replace function public.is_pro(p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from user_entitlements e where e.user_id = p_user and e.plan_type = 'pro'
                   and e.subscription_status = 'active' and (e.pro_expires_at is null or e.pro_expires_at > now()));
$$;

create or replace function public.plan_limit(p_feature text, p_user uuid default auth.uid())
returns integer language sql stable security definer set search_path = public as $$
  select f.limit_value from plan_features f
   where f.plan_id = case when public.is_pro(p_user) then 'pro' else 'free' end and f.feature_key = p_feature;
$$;

create or replace function public.plan_allows(p_feature text, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select f.enabled from plan_features f
    where f.plan_id = case when public.is_pro(p_user) then 'pro' else 'free' end and f.feature_key = p_feature), true);
$$;

-- The user confirms "Continue with Free" (Pro is only granted by complete_payment()).
create or replace function public.choose_free_plan()
returns void language sql security definer set search_path = public as $$
  insert into user_entitlements (user_id, plan_chosen_at) values (auth.uid(), now())
  on conflict (user_id) do update set plan_chosen_at = coalesce(user_entitlements.plan_chosen_at, now());
$$;
grant execute on function public.choose_free_plan() to authenticated;

-- Sign-up: profile + entitlement row + link pending agreement invitations.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, first_name, last_name, username, phone, country, email, preferred_language)
  values (new.id, new.raw_user_meta_data->>'first_name', new.raw_user_meta_data->>'last_name',
          nullif(new.raw_user_meta_data->>'username', ''), nullif(new.raw_user_meta_data->>'phone', ''),
          coalesce(new.raw_user_meta_data->>'country', 'Cameroon'), new.email,
          coalesce(new.raw_user_meta_data->>'preferred_language', 'en'))
  on conflict (id) do nothing;
  insert into public.user_entitlements (user_id) values (new.id) on conflict do nothing;
  perform set_config('splitsure.rpc', 'on', true);
  update public.agreement_splits set user_id = new.id
   where user_id is null and lower(collaborator_email) = lower(new.email);
  return new;
end;
$$;

-- ============================================================
-- PAYMENTS (written only by the payments Edge Function / service role)
-- ============================================================
create table if not exists public.payment_transactions (
  id              uuid primary key default gen_random_uuid(),
  reference       text not null unique,
  user_id         uuid not null references auth.users(id) on delete cascade,
  type            text not null check (type in ('PRO_UPGRADE','AGREEMENT_GENERATION')),
  amount_fcfa     integer not null check (amount_fcfa > 0),
  provider        text not null check (provider in ('MTN','ORANGE')),
  phone           text not null,
  target_id       uuid,
  status          text not null default 'pending' check (status in ('pending','success','failed','cancelled')),
  provider_tx_id  text,
  provider_status text,
  message         text,
  raw             jsonb,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now(),
  completed_at    timestamptz
);
create index if not exists payment_transactions_user_idx on public.payment_transactions(user_id, created_at desc);
-- An agreement can only be paid for once.
create unique index if not exists payment_one_success_per_agreement on public.payment_transactions(target_id)
  where type = 'AGREEMENT_GENERATION' and status = 'success';
alter table public.payment_transactions enable row level security;
drop policy if exists "Users read own payments" on public.payment_transactions;
create policy "Users read own payments" on public.payment_transactions for select using (auth.uid() = user_id);

-- ── Final agreement documents (unlocked by Pro or a 50 FCFA payment)
create table if not exists public.agreement_documents (
  agreement_id   uuid primary key references public.agreements(id) on delete cascade,
  unlocked_via   text not null check (unlocked_via in ('pro','payment')),
  transaction_id uuid references public.payment_transactions(id),
  unlocked_by    uuid references auth.users(id),
  pdf_path       text,
  generated_at   timestamptz,
  created_at     timestamptz default now()
);
alter table public.agreement_documents enable row level security;
drop policy if exists "Parties read agreement documents" on public.agreement_documents;
create policy "Parties read agreement documents" on public.agreement_documents for select
  using (public.is_agreement_party(agreement_id));

-- Pro users unlock final generation directly (once all parties accepted).
create or replace function public.unlock_agreement_with_pro(p_agreement uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_status text;
begin
  if not public.is_agreement_party(p_agreement) then raise exception 'Not allowed.'; end if;
  if not public.is_pro(auth.uid()) then raise exception 'PRO_REQUIRED'; end if;
  select status into v_status from agreements where id = p_agreement;
  if v_status <> 'accepted' then raise exception 'All parties must accept the agreement first.'; end if;
  insert into agreement_documents (agreement_id, unlocked_via, unlocked_by)
  values (p_agreement, 'pro', auth.uid()) on conflict (agreement_id) do nothing;
end;
$$;
grant execute on function public.unlock_agreement_with_pro(uuid) to authenticated;

-- Record where the final PDF was stored (only once unlocked).
create or replace function public.record_final_pdf(p_agreement uuid, p_path text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_agreement_party(p_agreement) then raise exception 'Not allowed.'; end if;
  update agreement_documents set pdf_path = p_path, generated_at = coalesce(generated_at, now())
   where agreement_id = p_agreement;
  if not found then raise exception 'PAYMENT_REQUIRED'; end if;
  perform set_config('splitsure.rpc', 'on', true);
  update agreements set pdf_path = p_path where id = p_agreement;
end;
$$;
grant execute on function public.record_final_pdf(uuid, text) to authenticated;

-- Final PDFs can only be uploaded after unlock (previous upload policy replaced).
drop policy if exists "Agreement PDF upload" on storage.objects;
drop policy if exists "Agreement PDF update" on storage.objects;
create policy "Agreement PDF upload" on storage.objects for insert
  with check (bucket_id = 'agreement-pdfs'
              and public.is_agreement_party(((storage.foldername(name))[1])::uuid)
              and exists (select 1 from public.agreement_documents d
                           where d.agreement_id = ((storage.foldername(name))[1])::uuid));
create policy "Agreement PDF update" on storage.objects for update
  using (bucket_id = 'agreement-pdfs'
         and public.is_agreement_party(((storage.foldername(name))[1])::uuid)
         and exists (select 1 from public.agreement_documents d
                      where d.agreement_id = ((storage.foldername(name))[1])::uuid));

-- Called by the payments Edge Function after verifying the transaction with MeSomb.
-- Idempotent: a transaction is applied at most once.
create or replace function public.complete_payment(
  p_reference text, p_success boolean, p_provider_tx_id text, p_provider_status text, p_message text, p_raw jsonb)
returns text language plpgsql security definer set search_path = public as $$
declare t payment_transactions;
begin
  select * into t from payment_transactions where reference = p_reference for update;
  if t.id is null then raise exception 'Unknown transaction'; end if;
  if t.status = 'success' then return 'already_applied'; end if;

  if not p_success then
    update payment_transactions
       set status = case when p_provider_status ilike '%cancel%' then 'cancelled' else 'failed' end,
           provider_tx_id = coalesce(p_provider_tx_id, provider_tx_id), provider_status = p_provider_status,
           message = p_message, raw = p_raw, updated_at = now(), completed_at = now()
     where id = t.id;
    if t.type = 'PRO_UPGRADE' then
      update user_entitlements set payment_status = 'failed', updated_at = now()
       where user_id = t.user_id and plan_type = 'free';
    end if;
    perform notify_user(t.user_id, 'payment_failed', 'payment', t.id,
      jsonb_build_object('amount', t.amount_fcfa, 'type', t.type), 'Payment failed', p_message);
    return 'failed';
  end if;

  update payment_transactions
     set status = 'success', provider_tx_id = p_provider_tx_id, provider_status = p_provider_status,
         message = p_message, raw = p_raw, updated_at = now(), completed_at = now()
   where id = t.id;

  if t.type = 'PRO_UPGRADE' then
    insert into user_entitlements (user_id) values (t.user_id) on conflict do nothing;
    update user_entitlements
       set plan_type = 'pro', subscription_status = 'active', payment_status = 'paid',
           pro_activated_at = coalesce(pro_activated_at, now()),
           pro_expires_at = (select case when p.duration_days is null then null
                                         else now() + make_interval(days => p.duration_days) end
                               from plans p where p.id = 'pro'),
           plan_chosen_at = coalesce(plan_chosen_at, now()), updated_at = now()
     where user_id = t.user_id;
    perform notify_user(t.user_id, 'pro_activated', 'payment', t.id, '{}'::jsonb, 'Pro activated', null);
  else
    insert into agreement_documents (agreement_id, unlocked_via, transaction_id, unlocked_by)
    values (t.target_id, 'payment', t.id, t.user_id) on conflict (agreement_id) do nothing;
  end if;
  perform notify_user(t.user_id, 'payment_success', 'payment', t.id,
    jsonb_build_object('amount', t.amount_fcfa, 'type', t.type), 'Payment successful', null);
  return 'applied';
end;
$$;
revoke all on function public.complete_payment(text, boolean, text, text, text, jsonb) from public, anon, authenticated;

-- ============================================================
-- MUSIC PASSPORT
-- ============================================================
create table if not exists public.music_passports (
  user_id            uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  slug               text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{2,39}$'),
  stage_name         text not null,
  full_name          text,
  photo_url          text,
  primary_role       text not null,
  secondary_roles    text[] not null default '{}',
  skills             text[] not null default '{}',
  country            text,
  city               text,
  bio                text,
  contact_email      text,
  contact_phone      text,
  preferred_contact  text check (preferred_contact in ('email','phone','whatsapp','in_app')),
  years_experience   int check (years_experience between 0 and 80),
  genres             text[] not null default '{}',
  instruments        text[] not null default '{}',
  languages          text[] not null default '{}',
  availability       text not null default 'available' check (availability in ('available','limited','unavailable')),
  arrangements       text[] not null default '{}',
  operating_location text,
  links              jsonb not null default '{}'::jsonb,
  visibility         jsonb not null default '{"contact": false, "location": true, "portfolio": true, "links": true, "experience": true}'::jsonb,
  is_published       boolean not null default false,
  created_at         timestamptz default now(),
  updated_at         timestamptz default now()
);
alter table public.music_passports enable row level security;
drop policy if exists "Owner manages passport" on public.music_passports;
create policy "Owner manages passport" on public.music_passports for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.passport_portfolio_items (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind        text not null check (kind in ('project','release','album','production_credit','writing_credit',
                                            'collaboration','video','award','experience')),
  title       text not null,
  role        text,
  year        int,
  url         text,
  image_url   text,
  description text,
  is_public   boolean not null default true,
  sort_order  int not null default 0,
  created_at  timestamptz default now()
);
create index if not exists portfolio_user_idx on public.passport_portfolio_items(user_id, sort_order);
alter table public.passport_portfolio_items enable row level security;
drop policy if exists "Owner manages portfolio" on public.passport_portfolio_items;
create policy "Owner manages portfolio" on public.passport_portfolio_items for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Public views: only published passports, only fields the owner made public.
create or replace view public.public_passports as
select p.user_id, p.slug, p.stage_name, p.photo_url, p.primary_role, p.secondary_roles, p.skills,
       case when (p.visibility->>'location')::boolean then p.country end as country,
       case when (p.visibility->>'location')::boolean then p.city end as city,
       case when (p.visibility->>'location')::boolean then p.operating_location end as operating_location,
       p.bio,
       case when (p.visibility->>'experience')::boolean then p.years_experience end as years_experience,
       p.genres, p.instruments, p.languages, p.availability, p.arrangements,
       case when (p.visibility->>'links')::boolean then p.links else '{}'::jsonb end as links,
       case when (p.visibility->>'contact')::boolean then p.contact_email end as contact_email,
       case when (p.visibility->>'contact')::boolean then p.contact_phone end as contact_phone,
       case when (p.visibility->>'contact')::boolean then p.preferred_contact end as preferred_contact,
       coalesce((p.visibility->>'portfolio')::boolean, true) as portfolio_public,
       p.updated_at
  from public.music_passports p
 where p.is_published;

create or replace view public.public_portfolio_items as
select i.id, i.user_id, i.kind, i.title, i.role, i.year, i.url, i.image_url, i.description, i.sort_order
  from public.passport_portfolio_items i
  join public.music_passports p on p.user_id = i.user_id
 where p.is_published and i.is_public and coalesce((p.visibility->>'portfolio')::boolean, true);

grant select on public.public_passports, public.public_portfolio_items to anon, authenticated;

-- The signed-in user's roles (primary + secondary) for opportunity matching.
create or replace function public.my_roles()
returns text[] language sql stable security definer set search_path = public as $$
  select coalesce((select array_prepend(primary_role, secondary_roles) from music_passports
                    where user_id = auth.uid()), '{}');
$$;

create or replace function public.slug_available(p_slug text)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from music_passports where slug = lower(p_slug) and user_id <> auth.uid());
$$;
grant execute on function public.slug_available(text) to authenticated;

insert into storage.buckets (id, name, public) values ('passport-media','passport-media',true)
on conflict (id) do nothing;
drop policy if exists "Passport media read"   on storage.objects;
drop policy if exists "Passport media write"  on storage.objects;
drop policy if exists "Passport media delete" on storage.objects;
create policy "Passport media read" on storage.objects for select using (bucket_id = 'passport-media');
create policy "Passport media write" on storage.objects for insert
  with check (bucket_id = 'passport-media' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Passport media delete" on storage.objects for delete
  using (bucket_id = 'passport-media' and auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- OPPORTUNITY HUB
-- ============================================================
create table if not exists public.collaboration_opportunities (
  id                   uuid primary key default gen_random_uuid(),
  owner_id             uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title                text not null,
  description          text not null,
  category             text not null check (category in ('recording','songwriting','production','performance',
                                                        'video','live','marketing','business','other')),
  required_roles       text[] not null default '{}',
  skills               text[] not null default '{}',
  genres               text[] not null default '{}',
  location             text,
  is_remote            boolean not null default true,
  collaboration_type   text not null check (collaboration_type in ('paid','revenue_share','royalty_share',
                                            'percentage_partnership','voluntary','negotiable')),
  compensation         text,
  deliverables         text,
  project_deadline     date,
  application_deadline date,
  positions            int not null default 1 check (positions between 1 and 50),
  reference_links      text[] not null default '{}',
  requirements         text,
  restrict_to_roles    boolean not null default false,
  status               text not null default 'open' check (status in ('open','closed')),
  created_at           timestamptz default now(),
  updated_at           timestamptz default now()
);
create index if not exists opportunities_open_idx on public.collaboration_opportunities(status, created_at desc);
create index if not exists opportunities_roles_idx on public.collaboration_opportunities using gin(required_roles);
alter table public.collaboration_opportunities enable row level security;

create table if not exists public.opportunity_applications (
  id             uuid primary key default gen_random_uuid(),
  opportunity_id uuid not null references public.collaboration_opportunities(id) on delete cascade,
  applicant_id   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  message        text not null,
  links          text[] not null default '{}',
  status         text not null default 'pending' check (status in ('pending','under_review','shortlisted',
                                                                     'accepted','rejected','withdrawn')),
  created_at     timestamptz default now(),
  updated_at     timestamptz default now(),
  unique (opportunity_id, applicant_id)
);
alter table public.opportunity_applications enable row level security;

create or replace function public.has_passport(p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from music_passports where user_id = p_user and is_published);
$$;

create or replace function public.is_opportunity_owner(p_opp uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from collaboration_opportunities where id = p_opp and owner_id = auth.uid());
$$;

create or replace function public.has_applied(p_opp uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from opportunity_applications where opportunity_id = p_opp and applicant_id = auth.uid());
$$;

-- Free: `opportunity_posts` limit (1) counted permanently; Pro: unlimited. Needs a Music Passport.
create or replace function public.can_post_opportunity()
returns boolean language plpgsql stable security definer set search_path = public as $$
declare v_limit int; v_used int;
begin
  if not public.has_passport(auth.uid()) then return false; end if;
  if public.is_pro(auth.uid()) then return true; end if;
  v_limit := public.plan_limit('opportunity_posts');
  if v_limit is null then return true; end if;
  select free_posts_used into v_used from user_entitlements where user_id = auth.uid();
  return coalesce(v_used, 0) < v_limit;
end;
$$;
grant execute on function public.can_post_opportunity() to authenticated;

drop policy if exists "Read visible opportunities" on public.collaboration_opportunities;
drop policy if exists "Post opportunities"         on public.collaboration_opportunities;
drop policy if exists "Owner updates opportunity"  on public.collaboration_opportunities;
drop policy if exists "Owner deletes opportunity"  on public.collaboration_opportunities;
create policy "Read visible opportunities" on public.collaboration_opportunities for select using (
  owner_id = auth.uid()
  or public.has_applied(id)
  or (status = 'open' and auth.role() = 'authenticated'
      and (not restrict_to_roles or cardinality(required_roles) = 0 or required_roles && public.my_roles()))
);
create policy "Post opportunities" on public.collaboration_opportunities for insert
  with check (owner_id = auth.uid() and public.can_post_opportunity());
create policy "Owner updates opportunity" on public.collaboration_opportunities for update
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "Owner deletes opportunity" on public.collaboration_opportunities for delete using (owner_id = auth.uid());

-- Count every post permanently (deleting a post never restores the allowance).
create or replace function public.count_opportunity_post()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into user_entitlements (user_id) values (new.owner_id) on conflict do nothing;
  update user_entitlements set free_posts_used = free_posts_used + 1, updated_at = now() where user_id = new.owner_id;
  return new;
end;
$$;
drop trigger if exists opportunities_count_post on public.collaboration_opportunities;
create trigger opportunities_count_post after insert on public.collaboration_opportunities
  for each row execute procedure public.count_opportunity_post();

-- Tell matching users about a new opportunity (role overlap, published passport, max 200, once).
create or replace function public.notify_opportunity_matches()
returns trigger language plpgsql security definer set search_path = public as $$
declare r record;
begin
  if cardinality(new.required_roles) = 0 then return new; end if;
  for r in select p.user_id from music_passports p
            where p.is_published and p.user_id <> new.owner_id
              and array_prepend(p.primary_role, p.secondary_roles) && new.required_roles
            limit 200 loop
    perform notify_user(r.user_id, 'opportunity_recommended', 'opportunity', new.id,
      jsonb_build_object('title', new.title), 'New opportunity for you', new.title);
  end loop;
  return new;
end;
$$;
drop trigger if exists opportunities_notify_matches on public.collaboration_opportunities;
create trigger opportunities_notify_matches after insert on public.collaboration_opportunities
  for each row execute procedure public.notify_opportunity_matches();

-- Applications
drop policy if exists "Read own or received applications" on public.opportunity_applications;
drop policy if exists "Apply to opportunities"            on public.opportunity_applications;
create policy "Read own or received applications" on public.opportunity_applications for select
  using (applicant_id = auth.uid() or public.is_opportunity_owner(opportunity_id));
create policy "Apply to opportunities" on public.opportunity_applications for insert with check (
  applicant_id = auth.uid() and status = 'pending' and public.has_passport(auth.uid())
  and exists (select 1 from collaboration_opportunities o where o.id = opportunity_id
               and o.status = 'open' and o.owner_id <> auth.uid()
               and (o.application_deadline is null or o.application_deadline >= current_date))
);

create or replace function public.notify_application_received()
returns trigger language plpgsql security definer set search_path = public as $$
declare o collaboration_opportunities; v_name text;
begin
  select * into o from collaboration_opportunities where id = new.opportunity_id;
  select stage_name into v_name from music_passports where user_id = new.applicant_id;
  perform notify_user(o.owner_id, 'application_received', 'opportunity', o.id,
    jsonb_build_object('title', o.title, 'name', coalesce(v_name, '')), 'New application', o.title);
  return new;
end;
$$;
drop trigger if exists applications_notify_owner on public.opportunity_applications;
create trigger applications_notify_owner after insert on public.opportunity_applications
  for each row execute procedure public.notify_application_received();

create or replace function public.set_application_status(p_application uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare a opportunity_applications; o collaboration_opportunities;
begin
  if p_status not in ('under_review','shortlisted','accepted','rejected') then raise exception 'Invalid status'; end if;
  select * into a from opportunity_applications where id = p_application for update;
  select * into o from collaboration_opportunities where id = a.opportunity_id;
  if o.owner_id is distinct from auth.uid() then raise exception 'Only the opportunity owner can do this.'; end if;
  if a.status = 'withdrawn' then raise exception 'This application was withdrawn.'; end if;
  if a.status = p_status then return; end if;
  update opportunity_applications set status = p_status, updated_at = now() where id = a.id;
  perform notify_user(a.applicant_id, 'application_' || p_status, 'opportunity', o.id,
    jsonb_build_object('title', o.title), 'Application update', o.title);
end;
$$;
grant execute on function public.set_application_status(uuid, text) to authenticated;

create or replace function public.withdraw_application(p_application uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update opportunity_applications set status = 'withdrawn', updated_at = now()
   where id = p_application and applicant_id = auth.uid() and status not in ('accepted','withdrawn');
  if not found then raise exception 'This application cannot be withdrawn.'; end if;
end;
$$;
grant execute on function public.withdraw_application(uuid) to authenticated;

-- Application counts for opportunity cards (visible to anyone who can see the opportunity).
create or replace function public.opportunity_application_count(p_opp uuid)
returns int language sql stable security definer set search_path = public as $$
  select count(*)::int from opportunity_applications where opportunity_id = p_opp and status <> 'withdrawn';
$$;
grant execute on function public.opportunity_application_count(uuid) to authenticated;

-- ============================================================
-- DEALFLOW – collaboration workspaces
-- ============================================================
create table if not exists public.collaboration_workspaces (
  id                 uuid primary key default gen_random_uuid(),
  owner_id           uuid not null default auth.uid() references auth.users(id) on delete cascade,
  opportunity_id     uuid references public.collaboration_opportunities(id) on delete set null,
  title              text not null,
  description        text,
  deliverables       text,
  payment_arrangement text,
  important_dates    text,
  status             text not null default 'negotiating' check (status in ('negotiating','agreed','in_protect',
                                                               'active','completed','cancelled')),
  agreement_id       uuid references public.agreements(id) on delete set null,
  created_at         timestamptz default now(),
  updated_at         timestamptz default now()
);
create unique index if not exists workspaces_one_per_opportunity on public.collaboration_workspaces(opportunity_id)
  where opportunity_id is not null;

create table if not exists public.workspace_members (
  workspace_id     uuid not null references public.collaboration_workspaces(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  display_name     text not null,
  role             text,
  responsibilities text,
  percentage       numeric(5,2) check (percentage is null or (percentage >= 0 and percentage <= 100)),
  agreed           boolean not null default false,
  is_owner         boolean not null default false,
  joined_at        timestamptz default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.workspace_messages (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.collaboration_workspaces(id) on delete cascade,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  body         text not null check (length(trim(body)) > 0),
  created_at   timestamptz default now()
);
create index if not exists workspace_messages_idx on public.workspace_messages(workspace_id, created_at);

alter table public.collaboration_workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.workspace_messages enable row level security;

create or replace function public.is_workspace_member(p_ws uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from workspace_members where workspace_id = p_ws and user_id = auth.uid());
$$;

drop policy if exists "Members read workspace"   on public.collaboration_workspaces;
drop policy if exists "Owner updates workspace"  on public.collaboration_workspaces;
drop policy if exists "Owner deletes workspace"  on public.collaboration_workspaces;
create policy "Members read workspace" on public.collaboration_workspaces for select
  using (owner_id = auth.uid() or public.is_workspace_member(id));
create policy "Owner updates workspace" on public.collaboration_workspaces for update using (owner_id = auth.uid());
create policy "Owner deletes workspace" on public.collaboration_workspaces for delete using (owner_id = auth.uid());

drop policy if exists "Members read members" on public.workspace_members;
create policy "Members read members" on public.workspace_members for select using (public.is_workspace_member(workspace_id));

drop policy if exists "Members read messages" on public.workspace_messages;
drop policy if exists "Members post messages" on public.workspace_messages;
create policy "Members read messages" on public.workspace_messages for select using (public.is_workspace_member(workspace_id));
create policy "Members post messages" on public.workspace_messages for insert
  with check (user_id = auth.uid() and public.is_workspace_member(workspace_id));

-- Owner accepts an applicant → workspace for that opportunity (created once) + member.
create or replace function public.start_workspace_from_application(p_application uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare a opportunity_applications; o collaboration_opportunities; v_ws uuid; v_owner_name text; v_name text; v_new boolean := false;
begin
  select * into a from opportunity_applications where id = p_application;
  select * into o from collaboration_opportunities where id = a.opportunity_id;
  if o.owner_id is distinct from auth.uid() then raise exception 'Only the opportunity owner can do this.'; end if;
  if a.status <> 'accepted' then raise exception 'Accept the application first.'; end if;

  select id into v_ws from collaboration_workspaces where opportunity_id = o.id;
  if v_ws is null then
    insert into collaboration_workspaces (owner_id, opportunity_id, title, description, deliverables, payment_arrangement)
    values (o.owner_id, o.id, o.title, o.description, o.deliverables, o.compensation) returning id into v_ws;
    select coalesce(stage_name, '') into v_owner_name from music_passports where user_id = o.owner_id;
    insert into workspace_members (workspace_id, user_id, display_name, is_owner)
    values (v_ws, o.owner_id, coalesce(nullif(v_owner_name, ''), 'Owner'), true);
    v_new := true;
  end if;
  -- Re-opening the workspace for an existing member changes nothing (no reset, no duplicate notification).
  if exists (select 1 from workspace_members where workspace_id = v_ws and user_id = a.applicant_id) then
    return v_ws;
  end if;
  if (select status from collaboration_workspaces where id = v_ws) not in ('negotiating','agreed') then
    raise exception 'Terms are locked once the agreement is in Protect.';
  end if;
  select stage_name into v_name from music_passports where user_id = a.applicant_id;
  insert into workspace_members (workspace_id, user_id, display_name, role)
  values (v_ws, a.applicant_id, coalesce(v_name, 'Collaborator'),
          (select primary_role from music_passports where user_id = a.applicant_id));
  -- A new member means everyone agrees again.
  update workspace_members set agreed = false where workspace_id = v_ws;
  update collaboration_workspaces set status = 'negotiating', updated_at = now() where id = v_ws;
  perform notify_user(a.applicant_id, case when v_new then 'workspace_created' else 'member_added' end, 'workspace', v_ws,
    jsonb_build_object('title', o.title), 'Collaboration workspace', o.title);
  return v_ws;
end;
$$;
grant execute on function public.start_workspace_from_application(uuid) to authenticated;

-- Owner (any member) or the member themself proposes role / responsibilities / percentage.
-- Any change resets everyone's agreement and notifies the other members.
create or replace function public.update_member_terms(p_ws uuid, p_user uuid, p_role text, p_responsibilities text, p_percentage numeric)
returns void language plpgsql security definer set search_path = public as $$
declare w collaboration_workspaces; m record;
begin
  select * into w from collaboration_workspaces where id = p_ws;
  if not (w.owner_id = auth.uid() or p_user = auth.uid()) or not public.is_workspace_member(p_ws) then
    raise exception 'Not allowed.';
  end if;
  if w.status not in ('negotiating','agreed') then raise exception 'Terms are locked once the agreement is in Protect.'; end if;
  update workspace_members set role = p_role, responsibilities = p_responsibilities, percentage = p_percentage
   where workspace_id = p_ws and user_id = p_user;
  update workspace_members set agreed = false where workspace_id = p_ws;
  update collaboration_workspaces set status = 'negotiating', updated_at = now() where id = p_ws;
  for m in select user_id from workspace_members where workspace_id = p_ws and user_id <> auth.uid() loop
    perform notify_user(m.user_id, 'terms_updated', 'workspace', p_ws, jsonb_build_object('title', w.title),
      'Terms updated', w.title);
  end loop;
end;
$$;
grant execute on function public.update_member_terms(uuid, uuid, text, text, numeric) to authenticated;

create or replace function public.set_terms_agreed(p_ws uuid, p_agreed boolean)
returns text language plpgsql security definer set search_path = public as $$
declare v_total numeric; v_pending int; w collaboration_workspaces;
begin
  if not public.is_workspace_member(p_ws) then raise exception 'Not allowed.'; end if;
  select * into w from collaboration_workspaces where id = p_ws;
  if w.status not in ('negotiating','agreed') then raise exception 'Terms are locked.'; end if;
  update workspace_members set agreed = p_agreed where workspace_id = p_ws and user_id = auth.uid();
  select coalesce(sum(percentage), 0), count(*) filter (where not agreed) into v_total, v_pending
    from workspace_members where workspace_id = p_ws;
  if v_pending = 0 and v_total = 100 then
    update collaboration_workspaces set status = 'agreed', updated_at = now() where id = p_ws;
    return 'agreed';
  end if;
  update collaboration_workspaces set status = 'negotiating', updated_at = now() where id = p_ws;
  return 'negotiating';
end;
$$;
grant execute on function public.set_terms_agreed(uuid, boolean) to authenticated;

-- After the Protect agreement is created from the workspace.
create or replace function public.link_workspace_agreement(p_ws uuid, p_agreement uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update collaboration_workspaces set agreement_id = p_agreement, status = 'in_protect', updated_at = now()
   where id = p_ws and owner_id = auth.uid() and status = 'agreed';
  if not found then raise exception 'All members must agree on the terms first.'; end if;
end;
$$;
grant execute on function public.link_workspace_agreement(uuid, uuid) to authenticated;

create or replace function public.set_workspace_status(p_ws uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_status not in ('active','completed','cancelled') then raise exception 'Invalid status'; end if;
  update collaboration_workspaces set status = p_status, updated_at = now() where id = p_ws and owner_id = auth.uid();
  if not found then raise exception 'Only the workspace owner can do this.'; end if;
end;
$$;
grant execute on function public.set_workspace_status(uuid, text) to authenticated;

-- ============================================================
-- REACH is Pro-only; free projects are limited by plan_features
-- ============================================================
drop policy if exists "Owner campaigns" on public.campaigns;
drop policy if exists "Users manage own campaigns" on public.campaigns;
drop policy if exists "Owner reads campaigns" on public.campaigns;
drop policy if exists "Pro creates campaigns" on public.campaigns;
drop policy if exists "Owner updates campaigns" on public.campaigns;
drop policy if exists "Owner deletes campaigns" on public.campaigns;
create policy "Owner reads campaigns"   on public.campaigns for select using (auth.uid() = user_id);
create policy "Pro creates campaigns"   on public.campaigns for insert
  with check (auth.uid() = user_id and public.plan_allows('reach'));
create policy "Owner updates campaigns" on public.campaigns for update using (auth.uid() = user_id);
create policy "Owner deletes campaigns" on public.campaigns for delete using (auth.uid() = user_id);

drop policy if exists "Owner manages projects" on public.projects;
drop policy if exists "Owner reads projects"   on public.projects;
drop policy if exists "Owner creates projects" on public.projects;
drop policy if exists "Owner updates projects" on public.projects;
drop policy if exists "Owner deletes projects" on public.projects;
create policy "Owner reads projects"   on public.projects for select using (user_id = auth.uid());
create policy "Owner creates projects" on public.projects for insert with check (
  user_id = auth.uid()
  and (public.plan_limit('max_projects') is null
       or (select count(*) from public.projects p where p.user_id = auth.uid()) < public.plan_limit('max_projects')));
create policy "Owner updates projects" on public.projects for update using (user_id = auth.uid());
create policy "Owner deletes projects" on public.projects for delete using (user_id = auth.uid());

-- Realtime for the plan badge and workspace chat.
do $$ begin
  alter publication supabase_realtime add table public.user_entitlements;
exception when others then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.workspace_messages;
exception when others then null; end $$;
