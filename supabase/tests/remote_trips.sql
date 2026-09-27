-- Execute inside BEGIN/ROLLBACK. Uses the documented approving administrator.
set local role authenticated;
select set_config('request.jwt.claim.sub','892c4763-9309-4a90-9ea1-7f876c90fb2f',true);
do $$
declare e uuid; other uuid; t uuid; v uuid; d uuid; f uuid; p uuid; p2 uuid; passenger uuid;
 fields jsonb; pf jsonb; ff jsonb:='{"direction":"INBOUND","scheduled_departure_utc":"2026-09-01T08:00:00Z","scheduled_arrival_utc":"2026-09-01T10:00:00Z","status":"SCHEDULED"}';
begin
 e:=(public.create_event(gen_random_uuid(),'Trips rollback probe',2026,'2026-09-01','2026-09-20','USD')).id;
 other:=(public.create_event(gen_random_uuid(),'Other Trips rollback probe',2026,'2026-09-01','2026-09-20','USD')).id;
 perform set_config('uman.trip_probe_event',e::text,true);
 v:=public.save_vehicle(e,gen_random_uuid(),null,null,'{"name":"Synthetic van","vehicle_type":"VAN","capacity":1,"status":"AVAILABLE"}');
 d:=public.save_driver(e,gen_random_uuid(),null,null,'{"full_name":"Synthetic driver","status":"AVAILABLE"}');
 f:=public.save_flight(e,gen_random_uuid(),null,null,ff);
 p:=public.save_person(e,gen_random_uuid(),null,null,'{"first_name":"Synthetic","last_name":"One","status":"ACTIVE"}');
 p2:=public.save_person(e,gen_random_uuid(),null,null,'{"first_name":"Synthetic","last_name":"Two","status":"ACTIVE"}');
 fields:=jsonb_build_object('direction','INBOUND','origin','Airport','destination','Uman','scheduled_departure_utc','2026-09-01T11:00:00Z','scheduled_arrival_utc','2026-09-01T13:00:00Z','status','PLANNED','is_locked',true,'driver_id',d,'vehicle_id',v,'related_flight_id',f);
 t:=public.save_trip(e,gen_random_uuid(),null,null,fields);
 if (public.read_trip(e,t)->>'vehicle_capacity')::int<>1 then raise exception 'Vehicle assignment'; end if;
 if public.read_trip(e,t)->>'driver_id'<>d::text then raise exception 'Driver assignment'; end if;
 if (public.read_trip(e,t)->>'active_passengers')::int<>0 then raise exception 'Initial capacity'; end if;
 pf:=jsonb_build_object('trip_id',t,'person_id',p,'passenger_status','ASSIGNED','pickup_location',null);
 passenger:=public.save_trip_passenger(e,gen_random_uuid(),null,null,pf);
 if (public.read_trip(e,t)->>'active_passengers')::int<>1 then raise exception 'Exact capacity'; end if;
 perform public.save_trip_passenger(e,gen_random_uuid(),null,null,pf||jsonb_build_object('person_id',p2));
 if (public.read_trip(e,t)->>'active_passengers')::int<>2 then raise exception 'Overflow rejected'; end if;
 perform public.save_trip_passenger(e,null,passenger,1,pf||'{"passenger_status":"CANCELLED"}');
 if (public.read_trip(e,t)->>'active_passengers')::int<>1 then raise exception 'Cancelled capacity'; end if;
 perform public.save_trip_passenger(e,null,passenger,2,pf);
 perform public.delete_trip_passenger(e,passenger,3);
 if (public.read_trip(e,t)->>'active_passengers')::int<>1 then raise exception 'Deleted capacity'; end if;
 perform public.restore_trip_passenger(e,passenger,4);
 if (public.read_trip(e,t)->>'active_passengers')::int<>2 then raise exception 'Restore capacity'; end if;
 if exists(select 1 from public.trip_passengers where id=passenger and pickup_location is not null) then raise exception 'Inferred pickup'; end if;
 perform public.save_trip(e,null,t,1,fields||'{"actual_arrival_utc":"2026-09-01T13:00:00Z"}');
 if public.read_trip(e,t)->>'status'<>'PLANNED' then raise exception 'Silent completion'; end if;
 begin perform public.save_trip(e,null,t,1,fields); raise exception 'Stale accepted'; exception when serialization_failure then null; end;
 if (select count(*) from public.audit_entries where entity_id=t::text)<>2 then raise exception 'CAS audit atomicity'; end if;
 perform public.save_flight(e,null,f,1,ff||'{"status":"DELAYED"}');
 if not (public.read_trip(e,t)->>'flight_needs_review')::boolean then raise exception 'Missing advisory'; end if;
 if (select scheduled_departure_utc from public.trips where id=t)<>'2026-09-01T11:00:00Z'::timestamptz then raise exception 'Silent flight sync'; end if;
 begin perform public.save_trip(other,gen_random_uuid(),null,null,fields); raise exception 'Cross-event trip'; exception when foreign_key_violation then null; end;
 begin perform public.save_trip_passenger(other,gen_random_uuid(),null,null,pf); raise exception 'Cross-event passenger'; exception when foreign_key_violation then null; end;
 if (select count(*) from public.list_trips(other,'',false))<>0 then raise exception 'Event isolation'; end if;
 perform public.delete_trip(e,t,2); perform public.restore_trip(e,t,3);
 if (public.read_trip(e,t)->>'version')::int<>4 then raise exception 'Trip restore'; end if;
 if (select count(*) from public.audit_entries where entity_id=t::text)<>4 then raise exception 'Trip audit'; end if;
 begin update public.trips set status='COMPLETED' where id=t; raise exception 'Direct DML'; exception when insufficient_privilege then null; end;
end; $$;
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
do $$ begin
 if exists(select 1 from public.trips) or exists(select 1 from public.trip_passengers) then raise exception 'RLS isolation'; end if;
 begin perform public.list_trips(current_setting('uman.trip_probe_event')::uuid); raise exception 'Unauthorized RPC'; exception when insufficient_privilege then null; end;
end; $$;
set local role anon;
do $$ begin
 begin perform public.list_trips(current_setting('uman.trip_probe_event')::uuid); raise exception 'Anonymous RPC'; exception when insufficient_privilege then null; end;
end; $$;
select 'Trips hosted role smoke checks passed; rollback required' as result;
