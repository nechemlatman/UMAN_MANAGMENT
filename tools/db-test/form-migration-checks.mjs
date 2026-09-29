import { PGlite } from '@electric-sql/pglite';
import { readFile, readdir } from 'node:fs/promises';
import assert from 'node:assert/strict';

// Verify an upgrade with existing source data, not only an empty schema install.
export async function runFormMigrationChecks() {
 const db=new PGlite(); let checks=0;
 try {
  const actor='11111111-1111-4111-8111-111111111111';
  await db.exec(`create role anon nologin; create role authenticated nologin;
   create schema auth; create table auth.users(id uuid primary key);
   create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
   grant usage on schema auth,public to anon,authenticated; grant execute on function auth.uid() to anon,authenticated;
   create publication supabase_realtime; insert into auth.users values('${actor}');
   select set_config('request.jwt.claim.sub','${actor}',false);`);
  const dir=new URL('../../supabase/migrations/',import.meta.url);
  const files=(await readdir(dir)).filter(n=>n.endsWith('.sql')).sort();
  const upgrade=files.find(n=>n.endsWith('_legacy_draft_forms.sql'));
  for(const file of files.filter(n=>n<upgrade)) await db.exec(await readFile(new URL(file,dir),'utf8'));
  const scalar=async sql=>Object.values((await db.query(sql)).rows[0])[0];
  const event=await scalar(`insert into public.events(creation_request_id,name,year,start_date,end_date,base_currency,created_by,updated_by)
    values(gen_random_uuid(),'Upgrade fixture',2026,'2026-09-01','2026-09-30','USD','${actor}','${actor}') returning id`);
  await db.exec(`insert into public.event_members(event_id,user_id,created_by) values('${event}','${actor}','${actor}')`);
  const save=async(kind,fields)=>scalar(`select public.save_${kind}('${event}',gen_random_uuid(),null,null,'${JSON.stringify(fields)}'::jsonb)`);
  await save('flight',{direction:'INBOUND',status:'SCHEDULED',scheduled_departure_utc:'2026-09-01T10:00:00Z',scheduled_arrival_utc:'2026-09-01T12:00:00Z'});
  await save('trip',{direction:'LOCAL',origin:'Legacy origin',destination:'Legacy destination',status:'CONFIRMED',is_locked:false,scheduled_departure_utc:'2026-09-01T10:00:00Z',scheduled_arrival_utc:'2026-09-01T12:00:00Z'});
  await save('person',{first_name:'Existing',status:'ACTIVE'});
  const tables=['events','event_members','people','flights','trips','audit_entries'];
  const before={};
  for(const table of tables) before[table]=(await db.query(`select * from public.${table} order by 1,2`)).rows;
  await db.exec(await readFile(new URL(upgrade,dir),'utf8'));
  for(const table of tables) {
    assert.deepEqual((await db.query(`select * from public.${table} order by 1,2`)).rows,before[table]);checks++;
  }

  return checks;
 } finally { await db.close(); }
}
