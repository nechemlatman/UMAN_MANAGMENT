-- OPERATOR TEMPLATE: data provisioning only, not an automatic migration.
-- Use a trusted connection AFTER verifying project ref and migration history.
-- Replace all placeholders with APPROVED values. No passwords or keys belong here.
-- Actor must be the real approving/provisioning administrator's confirmed Auth ID.
-- User IDs must come from auth.users; never generate substitute Auth identities.
-- The two-manager template is for later use; owner-only staging was explicitly
-- approved on 2026-09-18 and is recorded in SUPABASE_ENVIRONMENT_STATUS.md.
begin;
select set_config('request.jwt.claim.sub', 'ACTOR_AUTH_UUID', true);
do $$
begin
  if (select count(*) from auth.users where id in
      ('ACTOR_AUTH_UUID'::uuid,'YONATAN_AUTH_UUID'::uuid,'YOSEF_AUTH_UUID'::uuid)
      and email_confirmed_at is not null and not is_anonymous)
      <> (select count(distinct x) from unnest(array[
        'ACTOR_AUTH_UUID','YONATAN_AUTH_UUID','YOSEF_AUTH_UUID']) as t(x)) then
    raise exception 'Every provisioning identity must be real and confirmed';
  end if;
  if 'YONATAN_AUTH_UUID' = 'YOSEF_AUTH_UUID' then
    raise exception 'Managers must have distinct identities';
  end if;
end;
$$;
insert into public.events(id,creation_request_id,name,year,start_date,end_date,
  base_currency,created_by,updated_by)
values ('EVENT_UUID',gen_random_uuid(),'APPROVED_EVENT_NAME',APPROVED_GREGORIAN_YEAR,
  'APPROVED_START_DATE','APPROVED_END_DATE','APPROVED_CURRENCY',
  'ACTOR_AUTH_UUID','ACTOR_AUTH_UUID');
insert into public.event_members(event_id,user_id,created_by) values
  ('EVENT_UUID','YONATAN_AUTH_UUID','ACTOR_AUTH_UUID'),
  ('EVENT_UUID','YOSEF_AUTH_UUID','ACTOR_AUTH_UUID');
commit;
