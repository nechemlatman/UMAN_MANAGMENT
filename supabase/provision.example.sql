-- OPERATOR TEMPLATE: not an automatic migration. Run once on a freshly migrated
-- project, using a trusted connection. Create confirmed Auth accounts first.
-- Replace UUID placeholders with Auth user IDs, never passwords or service keys.
-- actor must be the real authenticated administrator authorizing provisioning.
begin;
select set_config('request.jwt.claim.sub', 'ACTOR_AUTH_UUID', true);
insert into public.events(id,creation_request_id,name,year,start_date,end_date,
  base_currency,created_by,updated_by)
values ('EVENT_UUID',gen_random_uuid(),'Uman',2026,'2026-09-01','2026-09-20',
  'USD','ACTOR_AUTH_UUID','ACTOR_AUTH_UUID');
insert into public.event_members(event_id,user_id,created_by) values
  ('EVENT_UUID','YONATAN_AUTH_UUID','ACTOR_AUTH_UUID'),
  ('EVENT_UUID','YOSEF_AUTH_UUID','ACTOR_AUTH_UUID');
commit;
