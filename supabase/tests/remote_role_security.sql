-- Run only through trusted operator tooling. All mutations are rolled back.
-- Set uman.test_event and uman.test_actor to approved existing IDs in this transaction.
set local role authenticated;
do $$
declare event_uuid uuid := current_setting('uman.test_event')::uuid;
        actor_uuid uuid := current_setting('uman.test_actor')::uuid;
        current_version bigint; changed public.events;
begin
  if auth.uid() <> actor_uuid then raise exception 'Actor mismatch'; end if;
  select version into current_version from public.events where id=event_uuid;
  if not found then raise exception 'Approved member cannot read event'; end if;
  changed := public.update_event(event_uuid,current_version,'Transactional security probe');
  if changed.version <> current_version+1 or changed.updated_by <> actor_uuid then
    raise exception 'Version/attribution failure'; end if;
  if not exists(select 1 from public.audit_entries where event_id=event_uuid and
    operation='UPDATE' and actor_user_id=actor_uuid and new_value->>'name'='Transactional security probe') then
    raise exception 'Audit missing'; end if;
  begin
    perform public.update_event(event_uuid,current_version,'Stale probe');
    raise exception 'Stale update accepted';
  exception when serialization_failure then null; end;
  begin
    update public.events set name='Direct bypass' where id=event_uuid;
    raise exception 'Direct update accepted';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.event_members(event_id,user_id,created_by) values(event_uuid,actor_uuid,actor_uuid);
    raise exception 'Client membership insert accepted';
  exception when insufficient_privilege then null; end;
  begin
    delete from public.audit_entries where event_id=event_uuid;
    raise exception 'Audit deletion accepted';
  exception when insufficient_privilege then null; end;
end $$;
-- Synthetic non-member claims test, not a claim of a second real Auth login.
select set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
do $$
begin
  if exists(select 1 from public.events) or exists(select 1 from public.audit_entries) then
    raise exception 'Non-member can read protected data'; end if;
  begin
    perform public.update_event(current_setting('uman.test_event')::uuid,1,'Substituted event');
    raise exception 'Non-member update accepted';
  exception when insufficient_privilege then null; end;
  begin
    perform public.create_event(gen_random_uuid(),'Unauthorized',2026,'2026-09-18','2026-09-20','USD');
    raise exception 'Non-member can self-provision';
  exception when insufficient_privilege then null; end;
end $$;
