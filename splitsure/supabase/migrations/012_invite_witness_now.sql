-- ============================================================
-- SplitSure – Migration 012: ask the witness of an already-sent agreement
--
-- Agreements sent before migration 011 (or whose witness was added later) were
-- never sent to their witness. invite_witness() lets the creator ask the witness
-- to confirm the current version without publishing a new version: the witness
-- is linked to their account (in-app notification) and the app then calls the
-- `agreement-emails` Edge Function with { witness_only: true } to e-mail them.
-- The agreement then needs the witness's confirmation to become 'accepted'.
-- Safe to re-run.
-- ============================================================

create or replace function public.invite_witness(p_agreement uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $function$
declare a agreements; v_witness uuid;
begin
  select * into a from agreements where id = p_agreement for update;
  if a.id is null or a.user_id <> auth.uid() then raise exception 'Only the agreement creator can do this.'; end if;
  if a.status not in ('pending', 'changes_requested') then
    raise exception 'The witness can only be asked while the agreement is waiting for responses.';
  end if;
  if nullif(trim(coalesce(a.witness_email, '')), '') is null then
    raise exception 'Add the witness''s e-mail address first.';
  end if;
  if a.witness_invited_version = a.version then return a.version; end if;
  perform set_config('splitsure.rpc', 'on', true);
  select u.id into v_witness from auth.users u where lower(u.email) = lower(trim(a.witness_email)) limit 1;
  update agreements
     set witness_user_id = v_witness, witness_invited_version = version,
         witness_response = null, witness_note = null, witness_responded_at = null,
         witness_signature_code = null, witness_signed_via = null, updated_at = now()
   where id = p_agreement;
  if v_witness is not null and v_witness <> auth.uid() then
    perform notify_user(v_witness, 'agreement_witness_invited', 'agreement', p_agreement,
      jsonb_build_object('song', a.song_title, 'version', a.version), 'Witness an agreement', a.song_title);
  end if;
  return a.version;
end;
$function$;
revoke all on function public.invite_witness(uuid) from public, anon;
grant execute on function public.invite_witness(uuid) to authenticated;

notify pgrst, 'reload schema';
