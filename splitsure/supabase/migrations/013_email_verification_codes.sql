-- ============================================================
-- SplitSure – Migration 013: verify the e-mail with a 6-digit code
--
-- New accounts get a 6-digit code by e-mail (sent by the `agreement-emails`
-- Edge Function through the project's Gmail/Resend sender) and must enter it
-- before using the app. Only a SHA-256 hash of the code is stored, with an
-- expiry and an attempt counter. profiles.email_verified_at can only be set by
-- mark_email_verified() (service role). Accounts that existed before this
-- migration, and Google sign-ins, count as verified.
-- Safe to re-run.
-- ============================================================

alter table public.profiles add column if not exists email_verified_at timestamptz;

-- Everyone who already has an account is considered verified.
do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'profiles_guard_email_verified') then
    update public.profiles set email_verified_at = coalesce(email_verified_at, now());
  end if;
end $$;

create table if not exists public.email_verification_codes (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  code_hash  text not null,
  expires_at timestamptz not null,
  attempts   int  not null default 0,
  sent_at    timestamptz not null default now()
);
alter table public.email_verification_codes enable row level security;
-- No policies: only the service role (Edge Function) reads or writes this table.

-- Users can't mark themselves verified.
create or replace function public._guard_email_verified()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if current_setting('splitsure.verify', true) is distinct from 'on' then
    if tg_op = 'INSERT' then
      new.email_verified_at := null;
    else
      new.email_verified_at := old.email_verified_at;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists profiles_guard_email_verified on public.profiles;
create trigger profiles_guard_email_verified before insert or update on public.profiles
  for each row execute function public._guard_email_verified();

create or replace function public.mark_email_verified(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform set_config('splitsure.verify', 'on', true);
  update profiles set email_verified_at = coalesce(email_verified_at, now()) where id = p_user;
  perform set_config('splitsure.verify', '', true);
end;
$$;
revoke all on function public.mark_email_verified(uuid) from public, anon, authenticated;
grant execute on function public.mark_email_verified(uuid) to service_role;

notify pgrst, 'reload schema';
