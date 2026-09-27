export async function runAccommodationChecks({db,a,b,outsider,equal,denied,identity,scalar}) {
 await identity(a);
 const event=await scalar("select (public.create_event(gen_random_uuid(),'Accommodation checks',2026,'2026-09-01','2026-09-30','USD')).id");
 const other=await scalar("select (public.create_event(gen_random_uuid(),'Other accommodation',2026,'2026-09-01','2026-09-30','USD')).id");
 const json=o=>"'"+JSON.stringify(o).replaceAll("'","''")+"'::jsonb";
 const save=(kind,fields,id=null,version=null,scope=event,request='gen_random_uuid()')=>`select public.save_${kind}('${scope}',${request},${id?`'${id}'`:'null'},${version??'null'},${json(fields)})`;
 const af={name:'דירה Main',address:'Street 24',hebrew_address:'רחוב 24',floor:'2',entry_code:'123#',landlord_name:'Synthetic',landlord_phone:'+380123',notes:'Apartment note',status:'ACTIVE',total_cost:'12345678901234567890.012345',cost_currency:'USD',cost_notes:'Original amount'};
 const apt=await scalar(save('apartment',af));
 const rf={apartment_id:apt,name_or_number:'101',floor:'2',description:'Room',notes:'Room note'};
 const room=await scalar(save('room',rf));
 const bf={room_id:room,label:'Bed A',type:'REGULAR_BED',custom_type_name:null,position_notes:'Near window',is_active:true};
 const bed=await scalar(save('sleeping_place',bf));
 const bed2=await scalar(save('sleeping_place',{...bf,label:'Bed B'}));
 const person=await scalar(save('person',{first_name:'Synthetic',last_name:'One',status:'ACTIVE'}));
 const person2=await scalar(save('person',{first_name:'Synthetic',last_name:'Two',status:'ACTIVE'}));
 const xf={sleeping_place_id:bed,person_id:person,start_date:'2026-09-20',end_date:'2026-09-23',status:'ACTIVE',notes:null,is_locked:false};
 const assignment=await scalar(save('accommodation_assignment',xf));
 const overlapCount=`select jsonb_array_length(public.read_accommodation('${event}')->'overlaps')`;
 const tables=['apartments','rooms','sleeping_places','accommodation_assignments'];
 const kinds=['apartment','room','sleeping_place','accommodation_assignment'];
 const ids=[apt,room,bed,assignment], fields=[af,rf,bf,xf];
 await equal(overlapCount,0);
 await equal(`select total_cost::text from public.apartments where id='${apt}'`,af.total_cost);
 await equal(`select public.read_accommodation('${event}')->'apartments'->0->>'total_cost'`,af.total_cost);
 for(const [field,value] of Object.entries(af)) await equal(`select to_jsonb(t)->>'${field}' from public.apartments t where id='${apt}'`,value);
 for(const bad of [{name:' '},{address:''},{status:'WRONG'},{total_cost:'-1'},{total_cost:'NaN'},{total_cost:'Infinity'},{cost_currency:'ZZZ'}]) await denied(save('apartment',{...af,...bad}),'23514');
 await denied(save('room',{...rf,name_or_number:''}),'23514');
 await denied(save('sleeping_place',{...bf,type:'CUSTOM',custom_type_name:' \t '}),'23514');
 await denied(save('sleeping_place',{...bf,type:'UNKNOWN'}),'23514');
 const custom=await scalar(save('sleeping_place',{...bf,type:'CUSTOM',custom_type_name:'Extra mattress'}));
 await equal(`select custom_type_name from public.sleeping_places where id='${custom}'`,'Extra mattress');
 for(const dates of [{end_date:xf.start_date},{end_date:'2026-09-19'},{start_date:'2026-02-30'}]) await denied(save('accommodation_assignment',{...xf,...dates}),dates.start_date?'22008':'23514');
 await denied(save('accommodation_assignment',{...xf,is_locked:true,notes:' \t\n '}),'23514');
 const turnover=await scalar(save('accommodation_assignment',{...xf,person_id:person2,start_date:'2026-09-23',end_date:'2026-09-25'}));
 await equal(overlapCount,0); // End exclusive, same-day turnover.
 const overlap=await scalar(save('accommodation_assignment',{...xf,person_id:person2,start_date:'2026-09-22',end_date:'2026-09-23',status:'TEMPORARY',is_locked:true,notes:'Manager accepts overlap'}));
 await equal(overlapCount,1); // Temporary + lock still warns.
 await equal(`select public.read_accommodation('${event}')->'overlaps'->0->>'rule_code'`,'ACCOMMODATION_OVERLAP');
 await equal(`select count(*)::int from public.accommodation_assignments where sleeping_place_id='${bed}' and not is_deleted`,3);
 await equal(`select end_date::text from public.accommodation_assignments where id='${assignment}'`,'2026-09-23');
 await scalar(save('accommodation_assignment',{...xf,sleeping_place_id:bed2}));
 await equal(overlapCount,1); // Different bed never overlaps.
 const of={...xf,person_id:person2,start_date:'2026-09-22',end_date:'2026-09-23',status:'CANCELLED',is_locked:true,notes:'Explicit cancellation'};
 await scalar(save('accommodation_assignment',of,overlap,1)); await equal(overlapCount,0);
 await scalar(save('accommodation_assignment',{...of,status:'ACTIVE'},overlap,2)); await equal(overlapCount,1);
 await db.exec(`select public.delete_accommodation_assignment('${event}','${overlap}',3)`); await equal(overlapCount,0);
 await db.exec(`select public.restore_accommodation_assignment('${event}','${overlap}',4)`); await equal(overlapCount,1);
 await denied(save('accommodation_assignment',{...xf,sleeping_place_id:bed2},assignment,1),'22023');
 await denied(save('accommodation_assignment',{...xf,person_id:person2},assignment,1),'22023');
 await equal(`select sleeping_place_id from public.accommodation_assignments where id='${assignment}'`,bed);
 const foreignApt=await scalar(save('apartment',af,null,null,other));
 const foreignRoom=await scalar(save('room',{...rf,apartment_id:foreignApt},null,null,other));
 const foreignBed=await scalar(save('sleeping_place',{...bf,room_id:foreignRoom},null,null,other));
 const foreignPerson=await scalar(save('person',{first_name:'Foreign',last_name:'Person',status:'ACTIVE'},null,null,other));
 for(const [kind,f,table,id,key,foreign] of [
  ['room',rf,'rooms',room,'apartment_id',foreignApt],['sleeping_place',bf,'sleeping_places',bed,'room_id',foreignRoom],
  ['accommodation_assignment',xf,'accommodation_assignments',assignment,'sleeping_place_id',foreignBed],['accommodation_assignment',xf,'accommodation_assignments',assignment,'person_id',foreignPerson],
 ]) {
  await denied(save(kind,{...f,[key]:foreign}),'23503');
  await db.exec('reset role'); await denied(`update public.${table} set ${key}='${foreign}' where id='${id}'`,'23503'); await identity(a);
 }
 // Every entity has the same complete idempotency, CAS, audit and tombstone contract.
 for(let i=0;i<4;i++) {
  const [kind,table,id,f]=[kinds[i],tables[i],ids[i],fields[i]];
  const request=await scalar('select gen_random_uuid()');
  const created=await scalar(save(kind,f,null,null,event,`'${request}'`));
  await equal(save(kind,f,null,null,event,`'${request}'`),created);
  const altered={...f,[i===2?'position_notes':'notes']:'Different retry'};
  await denied(save(kind,altered,null,null,event,`'${request}'`),'40001');
  await denied(save(kind,f,null,null,other,`'${request}'`),'42501');
  await denied(save(kind,{...f,version:999}),'22023');
  await scalar(save(kind,f,id,1));
  await denied(save(kind,f,id,1),'40001');
  await denied(save(kind,f,id,null),'40001');
  await db.exec(`select public.delete_${kind}('${event}','${id}',2)`);
  await equal(`select is_deleted from public.${table} where id='${id}'`,true);
  await equal(`select deleted_at_utc is not null from public.${table} where id='${id}'`,true);
  await denied(`select public.restore_${kind}('${event}','${id}',2)`,'40001');
  await db.exec(`select public.restore_${kind}('${event}','${id}',3)`);
  await equal(`select version::int from public.${table} where id='${id}'`,4);
  await equal(`select deleted_at_utc from public.${table} where id='${id}'`,null);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${id}'`,4);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${id}' and actor_user_id<>'${a}'`,0);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${id}' and (new_value ? 'creation_payload' or new_value ? 'creation_request_id')`,0);
  await denied(`update public.${table} set is_deleted=true where id='${id}'`,'42501');
  await denied(`delete from public.${table} where id='${id}'`,'42501');
  await denied(`insert into public.${table}(event_id) values('${event}')`,'42501');
 }
 // Soft-deleting parent never cascades. Corrections/cancellation remain explicit.
 await db.exec(`select public.delete_apartment('${event}','${apt}',4)`);
 await equal(`select is_deleted from public.rooms where id='${room}'`,false);
 await equal(`select is_deleted from public.accommodation_assignments where id='${assignment}'`,false);
 await denied(save('room',rf),'23503');
 await denied(save('sleeping_place',bf),'23503');
 await denied(save('accommodation_assignment',xf),'23503');
 await scalar(save('accommodation_assignment',{...xf,status:'CANCELLED'},assignment,4));
 await db.exec(`select public.restore_apartment('${event}','${apt}',5)`);
 // Forced audit failure rolls back create/update/delete/restore for all four entities.
 await db.exec(`reset role; create function public.reject_accommodation_audit() returns trigger language plpgsql as $$ begin if new.entity_type=any(array['apartments','rooms','sleeping_places','accommodation_assignments']) then raise exception 'audit test'; end if; return new; end; $$; create trigger reject_accommodation_audit before insert on public.audit_entries for each row execute function public.reject_accommodation_audit();`);
 await identity(a);
 for(let i=0;i<4;i++) {
  const [kind,table,id,f]=[kinds[i],tables[i],ids[i],fields[i]];
  const version=Number(await scalar(`select version from public.${table} where id='${id}'`));
  const count=await scalar(`select count(*)::int from public.${table}`);
  await denied(save(kind,f),'P0001'); await equal(`select count(*)::int from public.${table}`,count);
  await denied(save(kind,f,id,version),'P0001'); await equal(`select version::int from public.${table} where id='${id}'`,version);
  await denied(`select public.delete_${kind}('${event}','${id}',${version})`,'P0001'); await equal(`select is_deleted from public.${table} where id='${id}'`,false);
  await db.exec(`reset role; update public.${table} set is_deleted=true,deleted_at_utc=now() where id='${id}'`); await identity(a);
  await denied(`select public.restore_${kind}('${event}','${id}',${version})`,'P0001'); await equal(`select is_deleted from public.${table} where id='${id}'`,true);
  await db.exec(`reset role; update public.${table} set is_deleted=false,deleted_at_utc=null where id='${id}'`); await identity(a);
 }
 await db.exec('reset role; drop trigger reject_accommodation_audit on public.audit_entries; drop function public.reject_accommodation_audit();');
 await equal(`select count(*)::int from pg_publication_tables where pubname='supabase_realtime' and tablename=any(array['${tables.join("','")}'])`,4);
 await equal(`select count(*)::int from pg_class where relname=any(array['${tables.join("','")}']) and relrowsecurity`,4);
 await equal(`select has_schema_privilege('authenticated','accommodation_private','USAGE')`,false);
 await equal(`select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='accommodation_private' and (has_function_privilege('anon',p.oid,'EXECUTE') or has_function_privilege('authenticated',p.oid,'EXECUTE'))`,0);
 for(const name of [...kinds.flatMap((k,i)=>['save_'+k,'delete_'+k,'restore_'+k,'list_'+tables[i]]),'read_accommodation']) {
  await equal(`select has_function_privilege('authenticated',p.oid,'EXECUTE') and not has_function_privilege('anon',p.oid,'EXECUTE') and p.proconfig @> array['search_path=""'] from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='${name}'`,true);
 }
 await identity(outsider);
 for(const t of tables) { await equal(`select count(*)::int from public.${t}`,0); await denied(`select public.list_${t}('${event}')`,'42501'); }
 await denied(`select public.read_accommodation('${event}')`,'42501');
 for(let i=0;i<4;i++) {
  await denied(save(kinds[i],fields[i]),'42501');
  await denied(`select public.delete_${kinds[i]}('${event}','${ids[i]}',1)`,'42501');
  await denied(`select public.restore_${kinds[i]}('${event}','${ids[i]}',1)`,'42501');
 }
 await identity('','anon');
 for(let i=0;i<4;i++) {
  await denied(`select * from public.${tables[i]}`,'42501'); await denied(save(kinds[i],fields[i]),'42501');
  await denied(`select public.list_${tables[i]}('${event}')`,'42501');
 }
 await denied(`select public.read_accommodation('${event}')`,'42501');
 await identity(a);
 await db.exec(`select public.archive_event('${event}',1)`);
 for(let i=0;i<4;i++) await denied(save(kinds[i],fields[i]),'40001');
 await equal(`select jsonb_array_length(public.read_accommodation('${other}')->'accommodation_assignments')`,0);
}
