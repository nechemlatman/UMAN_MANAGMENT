import { PGlite } from '@electric-sql/pglite';
import { readFile, readdir } from 'node:fs/promises';
import assert from 'node:assert/strict';

// Apply the original deployed schema first, seed real legacy rows, then upgrade.
export async function runTransportMigrationChecks() {
  const db = new PGlite();
  const user = '11111111-1111-4111-8111-111111111111';
  const approver = '22222222-2222-4222-8222-222222222222';
  let checks = 0;
  try {
    await db.exec(`create role anon nologin; create role authenticated nologin;
      create schema auth; create table auth.users(id uuid primary key);
      create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
      grant usage on schema auth,public to anon,authenticated;
      grant execute on function auth.uid() to anon,authenticated;
      create publication supabase_realtime;
      insert into auth.users values('${user}'),('${approver}');
      select set_config('request.jwt.claim.sub','${user}',false);`);
    const dir = new URL('../../supabase/migrations/', import.meta.url);
    const files = (await readdir(dir)).filter(n=>n.endsWith('.sql')).sort();
    const repair = files.find(n=>n.endsWith('_transport_foundation_repair.sql'));
    for (const file of files.filter(n=>n<repair)) await db.exec(await readFile(new URL(file,dir),'utf8'));
    const scalar = async sql => Object.values((await db.query(sql)).rows[0])[0];
    const event = '44444444-4444-4444-8444-444444444444';
    await db.exec(`insert into public.events(id,creation_request_id,name,year,start_date,end_date,base_currency,created_by,updated_by)
      values('${event}',gen_random_uuid(),'Legacy transport',2026,'2026-09-01','2026-09-20','USD','${user}','${user}');
      insert into public.event_members(event_id,user_id,created_by) values('${event}','${user}','${user}');`);
    const ids = [];
    for (const status of ['ACTIVE','INACTIVE']) {
      ids.push(await scalar(`select public.save_driver('${event}',gen_random_uuid(),null,null,
        '{"full_name":"Legacy ${status}","phone_number":"123","license_number":"Info","status":"${status}"}'::jsonb)`));
    }
    await db.exec(`select public.delete_driver('${event}','${ids[1]}',1)`);
    const before = (await db.query('select * from public.drivers order by status')).rows;
    const repairSql = await readFile(new URL(repair,dir),'utf8');
    await db.exec("select set_config('request.jwt.claim.sub','',false)");
    await assert.rejects(db.exec(repairSql), e=>e.code==='42501'); checks++;
    await db.exec('rollback');
    assert.equal(await scalar("select count(*)::int from public.drivers where status in ('ACTIVE','INACTIVE')"),2); checks++;
    await db.exec(`select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',false)`);
    await assert.rejects(db.exec(repairSql), e=>e.code==='42501'); checks++;
    await db.exec('rollback');
    await db.exec(`select set_config('request.jwt.claim.sub','${approver}',false)`);
    await db.exec(repairSql);
    for (const row of before) {
      const after = (await db.query(`select * from public.drivers where id='${row.id}'`)).rows[0];
      assert.equal(after.updated_by,approver); checks++;
      assert.equal(await scalar(`select actor_user_id::text from public.audit_entries where entity_id='${row.id}' and new_value ? 'migration'`),approver); checks++;
      assert.equal(after.status, row.status==='ACTIVE'?'AVAILABLE':'UNAVAILABLE'); checks++;
      assert.equal(Number(after.version),Number(row.version)+1); checks++;
      for (const field of ['id','event_id','full_name','phone_number','license_number','is_deleted','created_by','creation_request_id']) {
        assert.deepEqual(after[field],row[field]); checks++;
      }
      assert.equal(await scalar(`select old_value->>'status' from public.audit_entries where entity_id='${row.id}' and new_value ? 'migration'`),row.status); checks++;
      assert.equal(await scalar(`select new_value->>'status' from public.audit_entries where entity_id='${row.id}' and operation='CREATE'`),row.status); checks++;
    }
    return checks;
  } finally { await db.close(); }
}
