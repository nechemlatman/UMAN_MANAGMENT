-- Hosted database-role smoke test; caller must wrap in BEGIN/ROLLBACK.
-- Real previously approved administrator; synthetic records are never committed.
set local role authenticated;
select set_config('request.jwt.claim.sub','892c4763-9309-4a90-9ea1-7f876c90fb2f',true);
do $$
declare e uuid; other uuid; d uuid; v uuid; f uuid; p uuid; fp uuid;
 df jsonb:='{"full_name":"Transport rollback probe","status":"AVAILABLE","whatsapp_phone":"+9720000000"}';
 vf jsonb:='{"name":"Rollback van","vehicle_type":"VAN","capacity":2,"status":"IN_USE","color":"Blue"}';
 ff jsonb:='{"direction":"INBOUND","flight_number":"TEST","scheduled_departure_utc":"2026-09-01T10:00:00Z","scheduled_arrival_utc":"2026-09-01T12:00:00Z"}';
begin
 e:=(public.create_event(gen_random_uuid(),'Transport rollback probe',2026,'2026-09-01','2026-09-20','USD')).id;
 other:=(public.create_event(gen_random_uuid(),'Other rollback scope',2026,'2026-09-01','2026-09-20','USD')).id;
 perform set_config('uman.transport_probe_event',e::text,true);
 d:=public.save_driver(e,gen_random_uuid(),null,null,df);
 v:=public.save_vehicle(e,gen_random_uuid(),null,null,vf);
 f:=public.save_flight(e,gen_random_uuid(),null,null,ff);
 p:=public.save_person(e,gen_random_uuid(),null,null,'{"first_name":"Synthetic","last_name":"Probe","status":"ACTIVE"}');
 fp:=public.save_flight_passenger(e,gen_random_uuid(),null,null,jsonb_build_object('flight_id',f,'person_id',p));
 if public.read_driver(e,d)->>'whatsapp_phone'<>'+9720000000' then raise exception 'Driver fields'; end if;
 if public.read_vehicle(e,v)->>'color'<>'Blue' then raise exception 'Vehicle fields'; end if;
 perform public.save_driver(e,null,d,1,df||'{"status":"BUSY"}');
 begin perform public.save_driver(e,null,d,1,df); raise exception 'Stale accepted'; exception when serialization_failure then null; end;
 if (select count(*) from public.audit_entries where entity_id=d::text)<>2 then raise exception 'Failed CAS audit'; end if;
 perform public.delete_driver(e,d,2); perform public.restore_driver(e,d,3);
 if (public.read_driver(e,d)->>'version')::int<>4 then raise exception 'Driver restore'; end if;
 perform public.delete_vehicle(e,v,1); perform public.restore_vehicle(e,v,2);
 if (public.read_vehicle(e,v)->>'version')::int<>3 then raise exception 'Vehicle restore'; end if;
 perform public.set_flight_deleted(e,f,1,true); perform public.set_flight_deleted(e,f,2,false);
 perform public.set_flight_passenger_deleted(e,fp,1,true); perform public.set_flight_passenger_deleted(e,fp,2,false);
 if (select count(*) from public.audit_entries where entity_id=d::text)<>4 then raise exception 'Driver audit'; end if;
 if exists(select 1 from public.audit_entries where entity_id=d::text and actor_user_id<>auth.uid()) then raise exception 'Actor mismatch'; end if;
 if (select count(*) from public.list_drivers(other,'',false))<>0 then raise exception 'Scope leak'; end if;
 p:=public.save_person(other,gen_random_uuid(),null,null,'{"first_name":"Other","last_name":"Probe","status":"ACTIVE"}');
 begin perform public.save_flight_passenger(other,gen_random_uuid(),null,null,jsonb_build_object('flight_id',f,'person_id',p)); raise exception 'Cross-event accepted'; exception when foreign_key_violation then null; end;
 begin update public.drivers set status='OFF_DUTY' where id=d; raise exception 'Direct DML'; exception when insufficient_privilege then null; end;
 begin delete from public.audit_entries where entity_id=d::text; raise exception 'Audit DML'; exception when insufficient_privilege then null; end;
end; $$;
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
do $$ begin
 if exists(select 1 from public.drivers) or exists(select 1 from public.vehicles) or exists(select 1 from public.flights) then raise exception 'Outsider RLS'; end if;
 begin perform public.list_drivers(current_setting('uman.transport_probe_event')::uuid); raise exception 'Outsider RPC'; exception when insufficient_privilege then null; end;
end; $$;
set local role anon;
do $$ begin
 begin perform * from public.drivers; raise exception 'Anonymous read'; exception when insufficient_privilege then null; end;
 begin perform public.list_flights(current_setting('uman.transport_probe_event')::uuid,'',false); raise exception 'Anonymous RPC'; exception when insufficient_privilege then null; end;
end; $$;
select 'Transport/Flights hosted role smoke checks passed; rollback required' as result;

