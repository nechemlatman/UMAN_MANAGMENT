-- Read-only deployed schema/security assertions; throws on any missing guarantee.
do $$
declare tabs text[]:=array['apartments','rooms','sleeping_places','accommodation_assignments'];
 kinds text[]:=array['apartment','room','sleeping_place','accommodation_assignment'];
 i int; t text; fn record; count_functions int:=0;
begin
 foreach t in array tabs loop
  if not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname=t and c.relrowsecurity) then raise exception 'Missing table/RLS: %',t; end if;
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then raise exception 'Missing publication: %',t; end if;
  if not has_table_privilege('authenticated','public.'||t,'SELECT') or has_table_privilege('anon','public.'||t,'SELECT') or has_table_privilege('authenticated','public.'||t,'INSERT,UPDATE,DELETE') then raise exception 'Table grants: %',t; end if;
  if not exists(select 1 from pg_constraint where conrelid=('public.'||t)::regclass and contype='u' and pg_get_constraintdef(oid)='UNIQUE (event_id, id)') then raise exception 'Missing composite unique: %',t; end if;
 end loop;
 if (select count(*) from pg_constraint where conrelid=any(array['public.rooms'::regclass,'public.sleeping_places'::regclass,'public.accommodation_assignments'::regclass]) and contype='f' and cardinality(conkey)=2)<>4 then raise exception 'Composite foreign keys'; end if;
 if (select count(*) from pg_constraint where conrelid=any(array['public.apartments'::regclass,'public.rooms'::regclass,'public.sleeping_places'::regclass,'public.accommodation_assignments'::regclass]) and contype='c')<20 then raise exception 'Missing domain constraints'; end if;
 if has_schema_privilege('anon','accommodation_private','USAGE') or has_schema_privilege('authenticated','accommodation_private','USAGE') then raise exception 'Helper schema exposure'; end if;
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='accommodation_private' and (has_function_privilege('anon',p.oid,'EXECUTE') or has_function_privilege('authenticated',p.oid,'EXECUTE'))) then raise exception 'Helper execute exposure'; end if;
 for fn in select p.* from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and (p.proname='read_accommodation' or p.proname=any(array['save_apartment','delete_apartment','restore_apartment','list_apartments','save_room','delete_room','restore_room','list_rooms','save_sleeping_place','delete_sleeping_place','restore_sleeping_place','list_sleeping_places','save_accommodation_assignment','delete_accommodation_assignment','restore_accommodation_assignment','list_accommodation_assignments'])) loop
  count_functions:=count_functions+1;
  if has_function_privilege('anon',fn.oid,'EXECUTE') or not has_function_privilege('authenticated',fn.oid,'EXECUTE') or not fn.prosecdef or not fn.proconfig @> array['search_path=""'] then raise exception 'RPC privilege/search path: %',fn.proname; end if;
 end loop;
 if count_functions<>17 then raise exception 'RPC count: %',count_functions; end if;
 if exists(select 1 from pg_proc where proname='acc_rollback_reject_audit') then raise exception 'Smoke fixture leaked'; end if;
 if exists(select 1 from public.events where name in ('Accommodation rollback probe','Other accommodation rollback probe')) then raise exception 'Smoke records leaked'; end if;
end; $$;
select 'Accommodation catalog passed: four tables, four composite FKs, constraints, RLS, 17 restricted RPCs, private helpers, publication, no smoke residue' as result;
