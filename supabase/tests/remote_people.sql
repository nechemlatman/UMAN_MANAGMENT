-- Run ONLY within BEGIN/ROLLBACK with an approved administrator claim.
-- Synthetic values only. This is hosted role testing, not Auth/Realtime acceptance.
set local role authenticated;
select set_config('request.jwt.claim.sub','892c4763-9309-4a90-9ea1-7f876c90fb2f',true);
do $$
declare e public.events; other public.events; p uuid; request uuid:=gen_random_uuid();
 fields jsonb:='{"first_name":"Synthetic","last_name":"Person","phone":"+972 50-123-4567","hebrew_first_name":"בדיקה","status":"ACTIVE","passport_number":"SYNTHETIC-NOT-REAL","passport_expiration_date":"2030-02-28","custom_fields":{}}';
begin
 e:=public.create_event(gen_random_uuid(),'People rollback probe',2026,'2026-09-01','2026-09-20','USD');
 other:=public.create_event(gen_random_uuid(),'Other People scope',2026,'2026-09-01','2026-09-20','USD');
 perform set_config('uman.people_probe_event',e.id::text,true);
 p:=public.save_person(e.id,request,null,null,fields);
 if public.save_person(e.id,request,null,null,fields)<>p then raise exception 'Idempotency failed'; end if;
 if public.read_person(e.id,p)->>'passport_expiration_date'<>'2030-02-28' then raise exception 'Expiry failed'; end if;
 if (select count(*) from public.list_people(e.id,'בדיקה Synthetic'))<>1 then raise exception 'Search failed'; end if;
 if (select count(*) from public.list_people(other.id))<>0 then raise exception 'Event leakage'; end if;
 begin perform public.read_person(other.id,p); raise exception 'Cross-event details accepted';
 exception when insufficient_privilege then null; end;
 perform public.save_person(e.id,null,p,1,fields||'{"first_name":"Updated"}');
 begin perform public.save_person(e.id,null,p,1,fields); raise exception 'Stale save accepted';
 exception when serialization_failure then null; end;
 begin update public.people set first_name='Bypass' where id=p; raise exception 'Direct DML accepted';
 exception when insufficient_privilege then null; end;
 begin delete from public.people where id=p; raise exception 'Hard delete accepted';
 exception when insufficient_privilege then null; end;
 begin perform * from people_private.person_details; raise exception 'Private access accepted';
 exception when insufficient_privilege then null; end;
 perform public.set_person_deleted(e.id,p,2,true);
 if (select count(*) from public.list_people(e.id))<>0 then raise exception 'Deleted visible'; end if;
 if (select count(*) from public.list_people(e.id,'',true))<>1 then raise exception 'Tombstone missing'; end if;
 perform public.set_person_deleted(e.id,p,3,false);
 if public.read_person(e.id,p)->>'passport_number'<>'SYNTHETIC-NOT-REAL' then raise exception 'Restore lost details'; end if;
 if (select count(*) from public.audit_entries where entity_id=p::text)<>4 then raise exception 'Audit count'; end if;
 if exists(select 1 from public.audit_entries where entity_id=p::text and
   (new_value::text like '%SYNTHETIC-NOT-REAL%' or new_value ? 'passport_number')) then raise exception 'Passport audit leak'; end if;
 perform public.archive_event(e.id,1);
 begin perform public.save_person(e.id,null,p,4,fields); raise exception 'Archived mutation accepted';
 exception when serialization_failure then null; end;
end; $$;
-- Simulate an outsider using a transaction-local claim, no account provisioning.
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
do $$
begin
 if exists(select 1 from public.people) then raise exception 'Outsider RLS leakage'; end if;
 begin perform public.list_people(current_setting('uman.people_probe_event')::uuid);
 raise exception 'Outsider RPC accepted'; exception when insufficient_privilege then null; end;
end; $$;
set local role anon;
do $$
begin
 begin perform * from public.people; raise exception 'Anonymous read accepted';
 exception when insufficient_privilege then null; end;
end; $$;
