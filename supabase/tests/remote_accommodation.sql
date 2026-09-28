-- Self-contained, rollback-only hosted verification. No fixture survives.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','892c4763-9309-4a90-9ea1-7f876c90fb2f',true);
do $$
declare e uuid; other uuid; a uuid; r uuid; b uuid; b2 uuid; p uuid; p2 uuid; x uuid; y uuid; z uuid;
 af jsonb:='{"name":"Synthetic apartment","address":"Synthetic street","status":"ACTIVE","total_cost":"12345678901234567890.012345","cost_currency":"USD"}';
 rf jsonb; bf jsonb; xf jsonb; yf jsonb; kinds text[]:=array['apartment','room','sleeping_place','accommodation_assignment'];
 tabs text[]:=array['apartments','rooms','sleeping_places','accommodation_assignments']; ids uuid[]; fields jsonb[];
 req uuid; created uuid; retried uuid; old_version bigint; current_version bigint; n int; i int;
begin
 e:=(public.create_event(gen_random_uuid(),'Accommodation rollback probe',2026,'2026-09-01','2026-09-30','USD')).id;
 other:=(public.create_event(gen_random_uuid(),'Other accommodation rollback probe',2026,'2026-09-01','2026-09-30','USD')).id;
 perform set_config('uman.acc_probe_event',e::text,true);
 a:=public.save_apartment(e,gen_random_uuid(),null,null,af);
 rf:=jsonb_build_object('apartment_id',a,'name_or_number','Room A');
 r:=public.save_room(e,gen_random_uuid(),null,null,rf);
 bf:=jsonb_build_object('room_id',r,'label','Bed A','type','REGULAR_BED','is_active',true);
 b:=public.save_sleeping_place(e,gen_random_uuid(),null,null,bf);
 b2:=public.save_sleeping_place(e,gen_random_uuid(),null,null,bf||'{"label":"Bed B"}');
 p:=public.save_person(e,gen_random_uuid(),null,null,'{"first_name":"Synthetic","last_name":"One","status":"ACTIVE"}');
 p2:=public.save_person(other,gen_random_uuid(),null,null,'{"first_name":"Synthetic","last_name":"Other","status":"ACTIVE"}');
 xf:=jsonb_build_object('sleeping_place_id',b,'person_id',p,'start_date','2026-09-20','end_date','2026-09-23','status','ACTIVE','is_locked',false);
 x:=public.save_accommodation_assignment(e,gen_random_uuid(),null,null,xf);
 yf:=xf||'{"start_date":"2026-09-23","end_date":"2026-09-25"}';
 y:=public.save_accommodation_assignment(e,gen_random_uuid(),null,null,yf);
 if jsonb_array_length(public.read_accommodation(e)->'overlaps')<>0 then raise exception 'Same-day turnover'; end if;
 yf:=xf||'{"start_date":"2026-09-22","end_date":"2026-09-23","status":"TEMPORARY","is_locked":true,"notes":"Manager accepts exception"}';
 perform public.save_accommodation_assignment(e,null,y,1,yf);
 if jsonb_array_length(public.read_accommodation(e)->'overlaps')<>1 then raise exception 'Temporary lock suppressed overlap'; end if;
 if public.read_accommodation(e)->'overlaps'->0->>'rule_code'<>'ACCOMMODATION_OVERLAP' then raise exception 'Advisory code'; end if;
 z:=public.save_accommodation_assignment(e,gen_random_uuid(),null,null,xf||jsonb_build_object('sleeping_place_id',b2));
 if jsonb_array_length(public.read_accommodation(e)->'overlaps')<>1 then raise exception 'Different bed'; end if;
 perform public.save_accommodation_assignment(e,null,y,2,yf||'{"status":"CANCELLED"}');
 if jsonb_array_length(public.read_accommodation(e)->'overlaps')<>0 then raise exception 'Cancelled included'; end if;
 perform public.save_accommodation_assignment(e,null,y,3,yf);
 perform public.delete_accommodation_assignment(e,y,4);
 if jsonb_array_length(public.read_accommodation(e)->'overlaps')<>0 then raise exception 'Deleted included'; end if;
 perform public.restore_accommodation_assignment(e,y,5);
 if jsonb_array_length(public.read_accommodation(e)->'overlaps')<>1 then raise exception 'Restore overlap'; end if;
 if (select end_date from public.accommodation_assignments where id=x)<>'2026-09-23'::date then raise exception 'Silent date rewrite'; end if;
 begin perform public.save_accommodation_assignment(e,null,x,1,xf||jsonb_build_object('sleeping_place_id',b2)); raise exception 'History rewritten'; exception when invalid_parameter_value then null; end;
 begin perform public.save_accommodation_assignment(e,gen_random_uuid(),null,null,xf||'{"end_date":"2026-09-20"}'); raise exception 'Zero nights'; exception when check_violation then null; end;
 begin perform public.save_accommodation_assignment(e,gen_random_uuid(),null,null,xf||'{"is_locked":true,"notes":"  "}'); raise exception 'Override without note'; exception when check_violation then null; end;
 begin perform public.save_sleeping_place(e,gen_random_uuid(),null,null,bf||'{"type":"CUSTOM","custom_type_name":"  "}'); raise exception 'Custom without name'; exception when check_violation then null; end;
 begin perform public.save_room(other,gen_random_uuid(),null,null,rf); raise exception 'Cross-event room'; exception when foreign_key_violation then null; end;
 begin perform public.save_sleeping_place(other,gen_random_uuid(),null,null,bf); raise exception 'Cross-event bed'; exception when foreign_key_violation then null; end;
 begin perform public.save_accommodation_assignment(other,gen_random_uuid(),null,null,xf||jsonb_build_object('person_id',p2)); raise exception 'Cross-event bed assignment'; exception when foreign_key_violation then null; end;
 begin perform public.save_accommodation_assignment(e,gen_random_uuid(),null,null,xf||jsonb_build_object('person_id',p2)); raise exception 'Cross-event person'; exception when foreign_key_violation then null; end;
 if public.read_accommodation(e)->'apartments'->0->>'total_cost'<>'12345678901234567890.012345' then raise exception 'Decimal precision'; end if;
 ids:=array[a,r,b,x]; fields:=array[af,rf,bf,xf];
 for i in 1..4 loop
  req:=gen_random_uuid();
  execute format('select public.save_%I($1,$2,null,null,$3)',kinds[i]) into created using e,req,fields[i];
  execute format('select public.save_%I($1,$2,null,null,$3)',kinds[i]) into retried using e,req,fields[i];
  if created<>retried then raise exception 'Idempotency'; end if;
  execute format('select public.save_%I($1,null,$2,1,$3)',kinds[i]) using e,ids[i],fields[i];
  begin execute format('select public.save_%I($1,null,$2,1,$3)',kinds[i]) using e,ids[i],fields[i]; raise exception 'Stale accepted'; exception when serialization_failure then null; end;
  execute format('select public.delete_%I($1,$2,2)',kinds[i]) using e,ids[i];
  execute format('select public.restore_%I($1,$2,3)',kinds[i]) using e,ids[i];
  execute format('select version from public.%I where id=$1',tabs[i]) into current_version using ids[i];
  if current_version<>4 then raise exception 'CAS lifecycle'; end if;
  select count(*) into n from public.audit_entries where entity_id=ids[i]::text;
  if n<>4 then raise exception 'Transactional audit'; end if;
  begin execute format('update public.%I set is_deleted=true where id=$1',tabs[i]) using ids[i]; raise exception 'Direct DML'; exception when insufficient_privilege then null; end;
 end loop;
 perform public.delete_apartment(e,a,4);
 if (select is_deleted from public.rooms where id=r) or (select is_deleted from public.accommodation_assignments where id=x) then raise exception 'Cascade deletion'; end if;
 perform public.restore_apartment(e,a,5);
 perform set_config('uman.acc_probe_ids',array_to_string(ids,','),true);
end; $$;
reset role;
-- Force an audit insertion failure inside a subtransaction; source writes must roll back.
create function public.acc_rollback_reject_audit() returns trigger language plpgsql as $$ begin
 if new.entity_type in ('apartments','rooms','sleeping_places','accommodation_assignments') then raise exception 'Synthetic audit failure'; end if; return new;
end; $$;
create trigger acc_rollback_reject_audit before insert on public.audit_entries for each row execute function public.acc_rollback_reject_audit();
set local role authenticated;
do $$ declare tabs text[]:=array['apartments','rooms','sleeping_places','accommodation_assignments']; kinds text[]:=array['apartment','room','sleeping_place','accommodation_assignment']; ids uuid[]:=string_to_array(current_setting('uman.acc_probe_ids'),',')::uuid[]; v bigint; after_v bigint; i int; e uuid:=current_setting('uman.acc_probe_event')::uuid; caught boolean;
begin
 for i in 1..4 loop
  execute format('select version from public.%I where id=$1',tabs[i]) into v using ids[i];
  caught:=false;
  begin execute format('select public.delete_%I($1,$2,$3)',kinds[i]) using e,ids[i],v; exception when raise_exception then caught:=true; end;
  if not caught then raise exception 'Audit failure did not abort'; end if;
  execute format('select version from public.%I where id=$1 and not is_deleted',tabs[i]) into after_v using ids[i];
  if after_v is distinct from v then raise exception 'Audit source rollback'; end if;
 end loop;
end; $$;
-- Use a syntactically valid outsider claim, with no new Auth account.
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
do $$ begin
 if exists(select 1 from public.apartments) or exists(select 1 from public.rooms) or exists(select 1 from public.sleeping_places) or exists(select 1 from public.accommodation_assignments) then raise exception 'RLS isolation'; end if;
 begin perform public.read_accommodation(current_setting('uman.acc_probe_event')::uuid); raise exception 'Outsider read'; exception when insufficient_privilege then null; end;
 begin perform public.save_apartment(current_setting('uman.acc_probe_event')::uuid,gen_random_uuid(),null,null,'{}'); raise exception 'Outsider write'; exception when insufficient_privilege then null; end;
end; $$;
set local role anon;
do $$ begin
 begin perform public.read_accommodation(current_setting('uman.acc_probe_event')::uuid); raise exception 'Anonymous read'; exception when insufficient_privilege then null; end;
 begin perform 1 from public.apartments; raise exception 'Anonymous table'; exception when insufficient_privilege then null; end;
end; $$;
reset role;
select 'Accommodation hosted role smoke passed; transaction rolled back' as result;
rollback;
