export async function runFormChecks({db,a,outsider,equal,denied,identity,scalar}) {
 await identity(a);
 const event=await scalar(`select (public.create_event(gen_random_uuid(),'Draft only',null,null,null,null)).id`);
 await equal(`select year is null and start_date is null and end_date is null and base_currency is null from public.events where id='${event}'`,true);
 await denied(`select public.transition_event('${event}',1,'READY')`,'22023');
 await db.exec(`reset role; update public.events set lifecycle_stage='READY' where id='${event}'`);
 await identity(a);
 await denied(`select public.transition_event('${event}',1,'TRAVEL')`,'22023');
 await equal(`select (public.edit_event_details('${event}',1,'Partial',null,null,null,null,'2026-09-01',null,null)).version::int`,2);
 await denied(`select public.edit_event_details('${event}',1,'Stale',null,null,null,null,null,null,null)`,'40001');
 const json=x=>`'${JSON.stringify(x)}'::jsonb`;
 const save=(kind,fields,id=null,version=null)=>`select public.save_${kind}('${event}',gen_random_uuid(),${id?`'${id}'`:'null'},${version},${json(fields)})`;
 const flight={direction:'INBOUND',status:'DRAFT'};
 const trip={direction:'LOCAL',status:'PLANNED',is_locked:false};
 const fid=await scalar(save('flight',flight));
 const tid=await scalar(save('trip',trip));
 await equal(`select airline is null and flight_number is null and departure_airport is null and arrival_airport is null and scheduled_departure_utc is null and scheduled_arrival_utc is null from public.flights where id='${fid}'`,true);
 await equal(`select origin is null and destination is null and scheduled_departure_utc is null and scheduled_arrival_utc is null from public.trips where id='${tid}'`,true);
 for(const status of ['SCHEDULED','DELAYED','DIVERTED','LANDED']) await denied(save('flight',{...flight,status},fid,1),'22023');
 for(const status of ['CONFIRMED','IN_PROGRESS','COMPLETED']) await denied(save('trip',{...trip,status},tid,1),'23514');
 for(const [kind,id,fields] of [['flight',fid,flight],['trip',tid,trip]]) {
   await scalar(save(kind,{...fields,scheduled_departure_utc:'2026-09-01T10:00:00+03:00'},id,1));
   await equal(`select scheduled_departure_utc='2026-09-01T07:00:00Z'::timestamptz and scheduled_arrival_utc is null from public.${kind}s where id='${id}'`,true);
   await denied(save(kind,fields,id,1),'40001');
   await denied(save(kind,{...fields,scheduled_departure_utc:'2026-09-01T10:00:00Z',scheduled_arrival_utc:'2026-09-01T09:00:00Z'},id,2),'23514');
   await equal(`select count(*)::int from public.audit_entries where entity_id='${id}'`,2);
   // Transactional audit failure rolls back draft edits as well as operational data.
   await db.exec(`reset role; create function public.form_reject_audit() returns trigger language plpgsql as $$begin raise exception 'audit blocked'; end;$$;
    create trigger form_reject_audit before insert on public.audit_entries for each row execute function public.form_reject_audit();`);
   await identity(a);
   await denied(save(kind,fields,id,2),'P0001');
   await equal(`select version::int from public.${kind}s where id='${id}'`,2);
   await db.exec('reset role; drop trigger form_reject_audit on public.audit_entries; drop function public.form_reject_audit();');
   await identity(outsider);
   await equal(`select count(*)::int from public.${kind}s where id='${id}'`,0);
   await denied(save(kind,fields,id,2),'42501');
   await identity('', 'anon');await denied(save(kind,fields),'42501');
   await identity(a);
 }
 // Relational identity remains mandatory, even when the parent is incomplete.
 await denied(save('flight_passenger',{flight_id:fid,status:'CONFIRMED'}),'23502');
 await denied(save('trip_passenger',{trip_id:tid,passenger_status:'ASSIGNED'}),'23503');
 await equal(`select (public.archive_event('${event}',2)).lifecycle_stage`,'ARCHIVED');
 await denied(save('flight',flight,fid,2),'40001');
}
