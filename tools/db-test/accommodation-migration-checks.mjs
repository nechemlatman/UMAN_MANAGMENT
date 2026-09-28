import { PGlite } from '@electric-sql/pglite';
import { readFile, readdir } from 'node:fs/promises';
import assert from 'node:assert/strict';

// Verify an upgrade with existing source data, not only an empty schema install.
export async function runAccommodationMigrationChecks() {
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
  const upgrade=files.find(n=>n.endsWith('_accommodation_draft_forms.sql'));
  for(const file of files.filter(n=>n<upgrade)) await db.exec(await readFile(new URL(file,dir),'utf8'));
  const scalar=async sql=>Object.values((await db.query(sql)).rows[0])[0];
  const event=await scalar(`insert into public.events(creation_request_id,name,year,start_date,end_date,base_currency,created_by,updated_by)
    values(gen_random_uuid(),'Upgrade fixture',2026,'2026-09-01','2026-09-30','USD','${actor}','${actor}') returning id`);
  await db.exec(`insert into public.event_members(event_id,user_id,created_by) values('${event}','${actor}','${actor}')`);
  const save=async(kind,fields)=>scalar(`select public.save_${kind}('${event}',gen_random_uuid(),null,null,'${JSON.stringify(fields)}'::jsonb)`);
  const apt=await save('apartment',{name:'Existing',address:'Existing street',status:'ACTIVE'});
  const room=await save('room',{apartment_id:apt,name_or_number:'101'});
  const bed=await save('sleeping_place',{room_id:room,label:'Existing bed',type:'REGULAR_BED',is_active:true});
  const person=await save('person',{first_name:'Existing',status:'ACTIVE'});
  const assignment=await save('accommodation_assignment',{sleeping_place_id:bed,person_id:person,start_date:'2026-09-20',end_date:'2026-09-23',status:'CANCELLED',is_locked:false});
  const tables=['apartments','rooms','sleeping_places','accommodation_assignments','audit_entries'];
  const before={};
  for(const table of tables) before[table]=(await db.query(`select * from public.${table} order by id`)).rows;
  await db.exec(await readFile(new URL(upgrade,dir),'utf8'));
  for(const table of tables) {
   const after=(await db.query(`select * from public.${table} order by id`)).rows;
   for(const row of after) { if(table==='accommodation_assignments') { assert.equal(row.has_been_operational,true); checks++; delete row.has_been_operational; } }
   assert.deepEqual(after,before[table]); checks++;
  }
  const draft=await save('accommodation_assignment',{status:'DRAFT',is_locked:false});
  assert.equal(await scalar(`select has_been_operational from public.accommodation_assignments where id='${draft}'`),false); checks++;
  await assert.rejects(db.exec(`select public.save_accommodation_assignment('${event}',null,'${assignment}',1,'{"status":"DRAFT","is_locked":false}'::jsonb)`),e=>e.code==='22023'); checks++;
  return checks;
 } finally { await db.close(); }
}
