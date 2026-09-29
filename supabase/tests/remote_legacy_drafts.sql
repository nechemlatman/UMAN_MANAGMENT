-- Rollback-only FORM-01 probe, shared by PGlite and linked staging.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','892c4763-9309-4a90-9ea1-7f876c90fb2f',true);
do $$
declare e uuid; f uuid; t uuid; fields jsonb;
begin
 e:=(public.create_event(gen_random_uuid(),'Legacy draft rollback probe',null,null,null,null)).id;
 if not (select year is null and start_date is null and end_date is null and base_currency is null from public.events where id=e) then raise exception 'Invented Event metadata'; end if;
 perform public.edit_event_details(e,1,'Partial event',null,null,null,null,'2026-09-01',null,null);
 begin perform public.edit_event_details(e,1,'Stale',null,null,null,null,null,null,null); raise exception 'Stale Event accepted'; exception when serialization_failure then null; end;
 begin perform public.transition_event(e,2,'READY'); raise exception 'Unresolved READY gate bypass'; exception when invalid_parameter_value then null; end;
 f:=public.save_flight(e,gen_random_uuid(),null,null,'{"direction":"INBOUND","status":"DRAFT"}');
 t:=public.save_trip(e,gen_random_uuid(),null,null,'{"direction":"LOCAL","status":"PLANNED","is_locked":false}');
 if not (select airline is null and flight_number is null and departure_airport is null and arrival_airport is null and scheduled_departure_utc is null and scheduled_arrival_utc is null from public.flights where id=f) then raise exception 'Invented Flight metadata'; end if;
 if not (select origin is null and destination is null and scheduled_departure_utc is null and scheduled_arrival_utc is null from public.trips where id=t) then raise exception 'Invented Trip metadata'; end if;
 begin perform public.save_flight(e,null,f,1,'{"direction":"INBOUND","status":"SCHEDULED"}'); raise exception 'Incomplete Flight operational'; exception when invalid_parameter_value then null; end;
 begin perform public.save_trip(e,null,t,1,'{"direction":"LOCAL","status":"CONFIRMED","is_locked":false}'); raise exception 'Incomplete Trip operational'; exception when check_violation then null; end;
 fields:='{"direction":"INBOUND","status":"DRAFT","scheduled_departure_utc":"2026-09-01T10:00:00+03:00"}';
 perform public.save_flight(e,null,f,1,fields);
 if not (select scheduled_departure_utc='2026-09-01T07:00:00Z'::timestamptz and scheduled_arrival_utc is null from public.flights where id=f) then raise exception 'UTC round trip'; end if;
 begin perform public.save_flight(e,null,f,1,fields); raise exception 'Stale Flight accepted'; exception when serialization_failure then null; end;
 perform public.set_flight_deleted(e,f,2,true);
 begin perform public.set_flight_deleted(e,f,2,false); raise exception 'Stale restore accepted'; exception when serialization_failure then null; end;
 perform public.set_flight_deleted(e,f,3,false);
 perform public.delete_trip(e,t,1);
 begin perform public.restore_trip(e,t,1); raise exception 'Stale Trip restore accepted'; exception when serialization_failure then null; end;
 perform public.restore_trip(e,t,2);
 if (select count(*) from public.audit_entries where event_id=e and entity_id=f::text)<>4 then raise exception 'Flight audit count'; end if;
 if (select count(*) from public.audit_entries where event_id=e and entity_id=t::text)<>3 then raise exception 'Trip audit count'; end if;
 if not (select scheduled_departure_utc is null and origin is null from public.trips where id=t) then raise exception 'Restore manufactured data'; end if;
end;
$$;
rollback;
