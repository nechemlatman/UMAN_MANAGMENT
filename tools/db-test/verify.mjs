import { PGlite } from '@electric-sql/pglite';
import { readFile, readdir } from 'node:fs/promises';
import assert from 'node:assert/strict';

// PostgreSQL WASM test harness. Auth roles/claims are emulated; this does not
// validate GoTrue, PostgREST, websocket delivery or simultaneous DB connections.
const db = new PGlite();
let checks = 0;
const a='11111111-1111-4111-8111-111111111111';
const b='22222222-2222-4222-8222-222222222222';
const outsider='33333333-3333-4333-8333-333333333333';
const event='44444444-4444-4444-8444-444444444444';
async function scalar(sql) {return Object.values((await db.query(sql)).rows[0])[0];}
async function equal(sql, value) {assert.equal(await scalar(sql),value); checks++;}
async function denied(sql, code) {
  await assert.rejects(db.exec(sql), e => e.code === code); checks++;
}
async function identity(id, role='authenticated') {
  await db.exec(`reset role; select set_config('request.jwt.claim.sub','${id}',false); set role ${role};`);
}
await db.exec(`
  create role anon nologin; create role authenticated nologin;
  create schema auth; create table auth.users(id uuid primary key);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
  grant usage on schema auth, public to anon, authenticated;
  grant execute on function auth.uid() to anon, authenticated;
  create publication supabase_realtime;
  insert into auth.users values('${a}'),('${b}'),('${outsider}');
`);
const migrations = new URL('../../supabase/migrations/', import.meta.url);
for (const name of (await readdir(migrations)).filter(n => n.endsWith('.sql')).sort()) {
  await db.exec(await readFile(new URL(name, migrations), 'utf8'));
}
checks++;
await db.exec(`select set_config('request.jwt.claim.sub','${a}',false);
  insert into public.events(id,creation_request_id,name,year,start_date,end_date,base_currency,created_by,updated_by)
  values('${event}',gen_random_uuid(),'Uman',2026,'2026-09-01','2026-09-20','USD','${a}','${a}');
  insert into public.event_members(event_id,user_id,created_by) values('${event}','${a}','${a}'),('${event}','${b}','${a}');`);
await identity('', 'anon');
await denied('select * from public.events','42501');
await denied(`select public.update_event('${event}',1,'Intrusion')`,'42501');
await identity(outsider);
await equal('select count(*)::int from public.events',0);
await equal('select count(*)::int from public.audit_entries',0);
await denied(`select public.update_event('${event}',1,'Intrusion')`,'42501');
await denied(`select public.create_event(gen_random_uuid(),'Intrusion',2026,'2026-09-01','2026-09-02','USD')`,'42501');
await denied(`insert into public.event_members(event_id,user_id,created_by) values('${event}','${outsider}','${outsider}')`,'42501');
await identity(a);
await equal('select count(*)::int from public.events',1);
await equal('select count(*)::int from public.event_members',1);
await equal(`select (public.update_event('${event}',1,'Yonatan update')).version::int`,2);
await equal(`select actor_user_id::text from public.audit_entries where operation='UPDATE'`,a);
await equal(`select old_value->>'name' from public.audit_entries where operation='UPDATE'`,'Uman');
await identity(b);
await equal('select name from public.events','Yonatan update');
await denied(`select public.update_event('${event}',1,'Stale Yosef edit')`,'40001');
await equal('select version::int from public.events',2);
await equal(`select count(*)::int from public.audit_entries where operation='UPDATE'`,1);
await equal(`select (public.update_event('${event}',2,'Yosef update')).version::int`,3);
await equal(`select updated_by::text from public.events`,b);
await denied(`update public.events set name='Bypass'`,'42501');
await denied(`delete from public.events`,'42501');
await denied(`update public.audit_entries set operation='FORGED'`,'42501');
await denied(`delete from public.audit_entries`,'42501');
await denied(`insert into public.audit_entries(event_id,actor_user_id,entity_type,entity_id,operation) values('${event}','${a}','events','fake','CREATE')`,'42501');
await denied(`select public.update_event('${event}',3,' ')`,'23514');
await equal('select version::int from public.events',3);
const request='55555555-5555-4555-8555-555555555555';
const create=`select (public.create_event('${request}','New event',2027,'2027-09-01','2027-09-20','USD')).id::text`;
const created=await scalar(create);
assert.equal(await scalar(create),created); checks++;
await denied(create.replace("'New event'","'Changed retry payload'"),'40001');
await equal(`select count(*)::int from public.events where id='${created}'`,1);
await equal(`select count(*)::int from public.event_members where event_id='${created}'`,1);
await equal(`select count(*)::int from public.audit_entries where event_id='${created}'`,2);
await identity(a);
await equal(`select count(*)::int from public.events where id='${created}'`,0);
await denied(create,'42501');
await denied(`select public.create_event(gen_random_uuid(),'Bad dates',2027,'2027-09-20','2027-09-01','USD')`,'23514');
// Force failure after Event and its audit insert: the RPC must roll all back.
await db.exec(`reset role;
  create function public.test_reject_member() returns trigger language plpgsql as $$
  begin raise exception 'injected membership failure'; end; $$;
  create trigger test_failure before insert on public.event_members for each row execute function public.test_reject_member();`);
await identity(a);
await denied(`select public.create_event('66666666-6666-4666-8666-666666666666','Atomic failure',2027,'2027-09-01','2027-09-20','USD')`,'P0001');
await db.exec('reset role; drop trigger test_failure on public.event_members;');
await equal(`select count(*)::int from public.events where name='Atomic failure'`,0);
await equal(`select count(*)::int from public.audit_entries where new_value->>'name'='Atomic failure'`,0);
await db.exec(`update public.events set lifecycle_stage='ARCHIVED' where id='${event}';`);
await identity(a);
await denied(`select public.update_event('${event}',3,'Archived edit')`,'40001');
await db.exec(`reset role; delete from public.event_members where event_id='${event}' and user_id='${b}';`);
await identity(b);
await equal(`select count(*)::int from public.events where id='${event}'`,0);
await denied(`select public.update_event('${event}',3,'Revoked edit')`,'42501');
await db.exec(`reset role; select set_config('request.jwt.claim.sub','${a}',false);
  insert into public.event_members(event_id,user_id,created_by) values('${event}','${b}','${a}');
  delete from public.event_members where event_id='${created}' and user_id='${b}';`);
await identity(b);
await denied(create,'42501');
// Event management regression matrix, using a fresh event and both role identities.
await identity(a);
const full = await scalar(`select (public.create_event(gen_random_uuid(),'Details',2026,'2026-09-01','2026-09-20','USD')).id::text`);
const edit = (version, currency='EUR') => `select (public.edit_event_details('${full}',${version},'Updated','שם','Description','Notes',2027,'2027-09-02','2027-09-22','${currency}')).version::int`;
await equal(edit(1),2);
await equal(`select hebrew_name from public.events where id='${full}'`,'שם');
await equal(`select manager_notes from public.events where id='${full}'`,'Notes');
await equal(`select year from public.events where id='${full}'`,2027);
await denied(edit(1),'40001');
await denied(edit(2,'bad'),'22023');
await denied(edit(2,'ZZZ'),'23514');
await denied(`select public.create_event(gen_random_uuid(),'Invalid currency',2026,'2026-09-01','2026-09-20','ZZZ')`,'23514');
await equal(`select count(*)::int from public.audit_entries where event_id='${full}'`,3);
await denied(`select public.transition_event('${full}',2,'READY')`,'22023');
await denied(`select public.transition_event('${full}',2,'ARCHIVED')`,'22023');
await equal(`select (public.soft_delete_event('${full}',2)).version::int`,3);
await denied(edit(3),'40001');
await denied(`select public.restore_event('${full}',2)`,'40001');
await equal(`select (public.restore_event('${full}',3)).version::int`,4);
await equal(`select lifecycle_stage from public.events where id='${full}'`,'PLANNING');
await equal(`select count(*)::int from public.audit_entries where event_id='${full}' and operation='RESTORE'`,1);
await identity(b);
await equal(`select count(*)::int from public.events where id='${full}'`,0);
for (const sql of [edit(4),`select public.archive_event('${full}',4)`, `select public.soft_delete_event('${full}',4)`, `select public.restore_event('${full}',4)`, `select public.transition_event('${full}',4,'TRAVEL')`]) await denied(sql,'42501');
await identity('', 'anon');
await denied(edit(4),'42501');
await denied(`select public.archive_event('${full}',4)`,'42501');
await identity(a);
await equal(`select (public.archive_event('${full}',4)).version::int`,5);
await denied(edit(5),'40001');
await denied(`select public.update_event('${full}',5,'Legacy bypass')`,'40001');
await denied(`select public.soft_delete_event('${full}',5)`,'40001');
await denied(`select public.transition_event('${full}',5,'CLOSEOUT')`,'40001');
await equal(`select count(*)::int from public.audit_entries where event_id='${full}' and operation='ARCHIVE'`,1);
await equal(`select count(*)::int from public.audit_entries where event_id='${full}' and actor_user_id <> '${a}'`,0);
await equal(`select has_function_privilege('authenticated','public.audit_material_change()','execute')`,false);
// Operator seeds READY only for testing later, already specified transitions.
await db.exec(`reset role; update public.events set lifecycle_stage='READY' where id='${full}';`);
await identity(a);
await equal(`select (public.transition_event('${full}',5,'TRAVEL')).version::int`,6);
await denied(`select public.transition_event('${full}',5,'IN_UMAN')`,'40001');
await equal(`select (public.transition_event('${full}',6,'IN_UMAN')).version::int`,7);
await equal(`select (public.transition_event('${full}',7,'DEPARTURE')).version::int`,8);
await equal(`select (public.transition_event('${full}',8,'CLOSEOUT')).version::int`,9);
await denied(`select public.transition_event('${full}',9,'PLANNING')`,'22023');
console.log(`PASS: ${checks} PostgreSQL migration, RLS, CAS, audit, Event management and transaction checks.`);
await db.close();
