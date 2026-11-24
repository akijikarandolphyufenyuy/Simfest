-- ============================================================
-- SplitSure – Migration 007: fix "infinite recursion detected in policy for relation projects"
--
-- The INSERT policy counted the user's projects with a sub-select on `projects`,
-- which re-applied the SELECT policies (projects → agreements → projects …) and
-- made every project insert fail with HTTP 500. The count now runs in a
-- SECURITY DEFINER function (no RLS re-entry) and still only for auth.uid(),
-- so the free-plan project limit stays enforced by the database. Safe to re-run.
-- ============================================================

create or replace function public.can_create_project()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.plan_limit('max_projects') is null
      or (select count(*) from public.projects where user_id = auth.uid()) < public.plan_limit('max_projects');
$$;

revoke execute on function public.can_create_project() from public, anon;
grant execute on function public.can_create_project() to authenticated;

drop policy if exists "Owner creates projects" on public.projects;
create policy "Owner creates projects" on public.projects
  for insert to authenticated
  with check (user_id = auth.uid() and public.can_create_project());

notify pgrst, 'reload schema';
