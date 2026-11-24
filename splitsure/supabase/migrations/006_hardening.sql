-- ============================================================
-- SplitSure – Migration 006: security hardening (DB advisor findings)
-- Safe to re-run.
-- ============================================================

-- 1. Internal helpers must not be callable through /rest/v1/rpc.
revoke execute on function public._snapshot_agreement(uuid, text) from public, anon, authenticated;
revoke execute on function public.process_subscription_expiry() from public, anon, authenticated;
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;

-- 2. Trigger functions: pin search_path.
alter function public.set_agreement_reference() set search_path = public;
alter function public.protect_accepted_agreement() set search_path = public;
alter function public.protect_accepted_splits() set search_path = public;

-- 3. Pro is granted only by the payments Edge Function (user_entitlements).
--    The old demo policy let any user insert a subscription row for themselves.
drop policy if exists "Users insert own demo subscriptions" on public.subscriptions;

notify pgrst, 'reload schema';
