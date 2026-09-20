export async function runPeopleChecks({db,a,b,outsider,equal,denied,identity,scalar}) {
  await identity(a);
  const event = await scalar("select (public.create_event(gen_random_uuid(),'People tests',2026,'2026-09-01','2026-09-20','USD')).id::text");
  const other = await scalar("select (public.create_event(gen_random_uuid(),'Other scope',2026,'2026-09-01','2026-09-20','USD')).id::text");
  await db.exec(`reset role; insert into public.event_members(event_id,user_id,created_by) values('${event}','${b}','${a}');`);
  await identity(a);
  const fields = {first_name:'David',last_name:'Cohen',hebrew_first_name:'דוד',hebrew_last_name:'כהן',
    phone:'+972 50-123-4567',whatsapp_phone:null,email:'test@example.invalid',passport_name:'SYNTHETIC',
    passport_number:'SYNTHETIC-NOT-REAL',passport_expiration_date:'2030-02-28',date_of_birth:'1990-01-02',
    nationality:'Test',emergency_contact_name:'Contact',emergency_contact_phone:'123',
    notes:'mixed עברית',custom_fields:{group:'test'},status:'ACTIVE'};
  const json = obj => "'"+JSON.stringify(obj).replaceAll("'","''")+"'::jsonb";
  const request = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const create = `select public.save_person('${event}','${request}',null,null,${json(fields)})::text`;
  const id = await scalar(create);
  await equal(create,id);
  await equal(`select count(*)::int from public.people where event_id='${event}'`,1);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${id}'`,1);
  await equal(`select public.read_person('${event}','${id}')->>'passport_expiration_date'`,'2030-02-28');
  for (const [key,value] of Object.entries(fields)) {
    await equal(`select public.read_person('${event}','${id}')->'${key}'`,value);
  }
  await equal(`select count(*)::int from public.list_people('${other}')`,0);
  for (const q of ['דוד Cohen','972501234567','עברית','dAvId','%']) {
    await equal(`select count(*)::int from public.list_people('${event}','${q}')`,q==='%'?0:1);
  }
  await equal(`select count(*)::int from public.person_duplicates('${event}',${json(fields)})`,1);
  await equal(`select count(*)::int from public.person_duplicates('${other}',${json(fields)})`,0);
  await denied(create.replace('David','Changed'),'40001');
  const update = (version,obj=fields,scope=event) => `select public.save_person('${scope}',null,'${id}',${version},${json(obj)})`;
  await denied(update(1,fields,other),'42501');
  await identity(b);
  await equal(`select public.read_person('${event}','${id}')->>'first_name'`,'David');
  await db.exec(update(1,{...fields,first_name:'Updated',passport_number:'NEW-SYNTHETIC'}));
  await denied(update(1),'40001');
  await equal(`select version::int from public.people where id='${id}'`,2);
  await equal(`select updated_by::text from public.people where id='${id}'`,b);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${id}'`,2);
  await equal(`select bool_and(not (new_value ? 'passport_number') and not (new_value::text like '%SYNTHETIC%')) from public.audit_entries where entity_id='${id}'`,true);
  await equal(`select new_value->'detail_fields_changed' ? 'passport_number' from public.audit_entries where entity_id='${id}' and operation='UPDATE'`,true);
  for (const [key,value] of [['first_name',' '],['status','BAD'],['email','bad'],['custom_fields',[]],['version',99]]) {
    await denied(update(2,{...fields,[key]:value}),'22023');
  }
  await denied(update(2,{...fields,passport_expiration_date:'2030-02-30'}),'22008');
  for (const sql of ['insert into public.people(first_name) values(\'Bypass\')',
    'update public.people set first_name=\'Bypass\'','delete from public.people',
    'select * from people_private.person_details']) await denied(sql,'42501');
  await denied(`select public.read_person('${other}','${id}')`,'42501');
  await db.exec(`select public.set_person_deleted('${event}','${id}',2,true)`);
  await equal(`select count(*)::int from public.list_people('${event}')`,0);
  await equal(`select count(*)::int from public.list_people('${event}','',true)`,1);
  await denied(update(3),'40001');
  await denied(`select public.set_person_deleted('${event}','${id}',2,false)`,'40001');
  await db.exec(`select public.set_person_deleted('${event}','${id}',3,false)`);
  await equal(`select public.read_person('${event}','${id}')->>'passport_number'`,'NEW-SYNTHETIC');
  await equal(`select count(*)::int from public.list_people('${event}')`,1);
  await identity(outsider);
  await equal('select count(*)::int from public.people',0);
  for (const sql of [create,update(4),`select * from public.list_people('${event}')`,
    `select public.read_person('${event}','${id}')`,
    `select * from public.person_duplicates('${event}',${json(fields)})`,
    `select public.set_person_deleted('${event}','${id}',4,true)`]) await denied(sql,'42501');
  await identity('','anon');
  await denied('select * from public.people','42501');
  await denied(create,'42501');
  await identity(a);
  // Inject a late failure: public/private rows and audit must roll back together.
  await db.exec(`reset role;
    create function public.reject_people_audit() returns trigger language plpgsql as $$
    begin if new.entity_type='people' then raise exception 'injected'; end if; return new; end; $$;
    create trigger reject_people_audit before insert on public.audit_entries for each row execute function public.reject_people_audit();`);
  await identity(a);
  await denied(update(4,{...fields,first_name:'Rollback'}),'P0001');
  await equal(`select public.read_person('${event}','${id}')->>'first_name'`,'Updated');
  await equal(`select public.read_person('${event}','${id}')->>'passport_number'`,'NEW-SYNTHETIC');
  await denied(create.replace(request,'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),'P0001');
  await equal(`select count(*)::int from public.people where event_id='${event}'`,1);
  await db.exec('reset role; drop trigger reject_people_audit on public.audit_entries;');
  await equal(`select count(*)::int from people_private.person_details where event_id='${event}'`,1);
  await equal("select count(*)::int from pg_publication_tables where schemaname='people_private'",0);
  await equal("select count(*)::int from pg_publication_tables where tablename='people'",1);
  await identity(a);
  await db.exec(`select public.archive_event('${event}',1)`);
  await denied(update(4),'40001');
  await denied(`select public.set_person_deleted('${event}','${id}',4,true)`,'40001');
  await equal(`select count(*)::int from public.list_people('${event}')`,1);
  await db.exec(`reset role; delete from public.event_members where event_id='${event}' and user_id='${b}';`);
  await identity(b);
  await equal(`select count(*)::int from public.people where event_id='${event}'`,0);
  await denied(update(4),'42501');
  await denied(`select public.read_person('${event}','${id}')`,'42501');
}
