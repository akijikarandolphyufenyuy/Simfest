-- ============================================================
-- SplitSure – Migration 005
-- Replace instagram_url with whatsapp_url on profiles.
-- Safe to re-run: uses DO block to check column existence first.
-- ============================================================

do $$
begin
  -- Rename instagram_url → whatsapp_url if the old column still exists
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'profiles'
      and column_name  = 'instagram_url'
  ) then
    alter table public.profiles rename column instagram_url to whatsapp_url;
  end if;

  -- Add whatsapp_url if neither column exists (fresh install after this migration)
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name   = 'profiles'
      and column_name  = 'whatsapp_url'
  ) then
    alter table public.profiles add column whatsapp_url text;
  end if;
end $$;
