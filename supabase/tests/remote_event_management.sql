-- Caller MUST wrap in BEGIN / ROLLBACK and set request.jwt.claim.sub to an
-- approved administrator. Uses only transaction-local fixture data.
-- This is a database-role test, NOT independent Auth/session acceptance.
set local role authenticated;
do $$
declare e public.events; v bigint; audit_count integer;
begin
  e := public.create_event(gen_random_uuid(),'Event management rollback probe',2026,'2026-09-01','2026-09-20','USD');
  perform set_config('uman.probe_event',e.id::text,true);
  e := public.edit_event_details(e.id,e.version,'Updated','שם','Description','Notes',2027,'2027-09-01','2027-09-20','EUR');
  if e.version<>2 or e.hebrew_name<>'שם' or e.manager_notes<>'Notes' or e.updated_by<>auth.uid() then
    raise exception 'Field/version/actor failure'; end if;
  select count(*) into audit_count from public.audit_entries where event_id=e.id;
  begin
    perform public.edit_event_details(e.id,1,'Stale',null,null,null,2027,'2027-09-01','2027-09-20','EUR');
    raise exception 'Stale edit accepted';
  exception when serialization_failure then null; end;
  begin
    perform public.transition_event(e.id,2,'READY');
    raise exception 'Undefined readiness accepted';
  exception when invalid_parameter_value then null; end;
  if (select count(*) from public.audit_entries where event_id=e.id)<>audit_count then
    raise exception 'Rejected write created audit'; end if;
  e := public.soft_delete_event(e.id,2);
  if not e.is_deleted or e.deleted_at_utc is null then raise exception 'Tombstone failure'; end if;
  begin
    perform public.restore_event(e.id,2);
    raise exception 'Stale restore accepted';
  exception when serialization_failure then null; end;
  e := public.restore_event(e.id,3);
  if e.is_deleted or e.lifecycle_stage<>'PLANNING' then raise exception 'Restore changed lifecycle'; end if;
  e := public.archive_event(e.id,4);
  begin
    perform public.update_event(e.id,5,'Legacy archive bypass');
    raise exception 'Archived rename accepted';
  exception when serialization_failure then null; end;
  begin
    perform public.transition_event(e.id,5,'CLOSEOUT');
    raise exception 'Archive reopening accepted';
  exception when serialization_failure then null; end;
  if (select count(*) from public.audit_entries where event_id=e.id)<>6 or
     (select count(*) from public.audit_entries where event_id=e.id and actor_user_id<>auth.uid())<>0 then
    raise exception 'Audit count/attribution failure'; end if;
end $$;
-- Revoke only the transaction-created fixture membership as the audited operator.
reset role;
delete from public.event_members where event_id=current_setting('uman.probe_event')::uuid;
set local role authenticated;
do $$
begin
  if exists(select 1 from public.events where id=current_setting('uman.probe_event')::uuid) then
    raise exception 'Revoked Event visible'; end if;
  begin
    perform public.restore_event(current_setting('uman.probe_event')::uuid,5);
    raise exception 'Revoked write accepted';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
