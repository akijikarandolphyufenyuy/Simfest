-- ============================================================
-- SplitSure – Migration 009: profiles for "Continue with Google" accounts
--
-- Google sign-ups carry full_name / given_name / family_name / avatar_url
-- (or picture) instead of the first_name / last_name the e-mail form sends.
-- The sign-up trigger now understands both, so Google users get a named
-- profile with their photo. Everything else is unchanged. Safe to re-run.
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare
  m jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_full text := nullif(trim(coalesce(m->>'full_name', m->>'name', '')), '');
  v_first text := nullif(trim(coalesce(m->>'first_name', m->>'given_name', '')), '');
  v_last text := nullif(trim(coalesce(m->>'last_name', m->>'family_name', '')), '');
begin
  -- Fall back to splitting the full name ("Amina Ngono Bella" → "Amina" / "Ngono Bella").
  if v_first is null and v_full is not null then
    v_first := split_part(v_full, ' ', 1);
    v_last := coalesce(v_last, nullif(trim(substr(v_full, length(split_part(v_full, ' ', 1)) + 1)), ''));
  end if;

  insert into public.profiles (id, first_name, last_name, username, phone, country, email, preferred_language, avatar_url)
  values (new.id, v_first, v_last,
          nullif(m->>'username', ''), nullif(m->>'phone', ''),
          coalesce(m->>'country', 'Cameroon'), new.email,
          coalesce(m->>'preferred_language', 'en'),
          nullif(coalesce(m->>'avatar_url', m->>'picture', ''), ''))
  on conflict (id) do nothing;
  insert into public.user_entitlements (user_id) values (new.id) on conflict do nothing;
  perform set_config('splitsure.rpc', 'on', true);
  update public.agreement_splits set user_id = new.id
   where user_id is null and lower(collaborator_email) = lower(new.email);
  return new;
end;
$function$;
