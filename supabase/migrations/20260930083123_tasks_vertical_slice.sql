begin;
create table public.tasks (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null references public.events(id),
 creation_request_id uuid not null unique, creation_payload jsonb not null,
 title text not null check(length(btrim(title)) between 1 and 500),
 description text check(length(description)<=10000), notes text check(length(notes)<=10000),
 assignee_id uuid, priority text check(priority in ('CRITICAL','HIGH','MEDIUM','LOW')),
 due_date_utc timestamptz check(due_date_utc is null or (isfinite(due_date_utc) and due_date_utc >= '0001-01-01 00:00:00+00'::timestamptz and due_date_utc < '10000-01-01 00:00:00+00'::timestamptz)),
 -- Creation starts the canonical lifecycle; metadata writes cannot supply status.
 status text not null default 'NEW' check(status in ('NEW','IN_PROGRESS','WAITING','COMPLETED','CANCELLED')),
 completed_at_utc timestamptz, cancelled_at_utc timestamptz,
 is_deleted boolean not null default false, deleted_at_utc timestamptz,
 created_at_utc timestamptz not null default now(), updated_at_utc timestamptz not null default now(),
 created_by uuid not null references auth.users(id), updated_by uuid not null references auth.users(id),
 version bigint not null default 1 check(version>0), unique(event_id,id),
 foreign key(event_id,assignee_id) references public.people(event_id,id),
 check(is_deleted=(deleted_at_utc is not null)),
 check((status is not distinct from 'COMPLETED')=(completed_at_utc is not null)),
 check((status is not distinct from 'CANCELLED')=(cancelled_at_utc is not null))
);
create index tasks_event_status_due on public.tasks(event_id,is_deleted,status,due_date_utc,id);
create index tasks_event_due on public.tasks(event_id,is_deleted,due_date_utc,id);
create index tasks_assignee on public.tasks(event_id,assignee_id);
create index tasks_created_by on public.tasks(created_by);
create index tasks_updated_by on public.tasks(updated_by);
alter table public.tasks enable row level security;
revoke all on public.tasks from public,anon,authenticated;
grant select on public.tasks to authenticated;
create policy tasks_read on public.tasks for select to authenticated using (
 public.is_event_admin(event_id) and exists(select 1 from public.events e where e.id=event_id and not e.is_deleted)
);
create schema tasks_private;
revoke all on schema tasks_private from public,anon,authenticated;

-- Narrow helpers use the mature membership/Event lock and read-only checks.
create function tasks_private.audit() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.audit_entries(event_id,actor_user_id,entity_type,entity_id,operation,old_value,new_value)
 values(new.event_id,auth.uid(),'tasks',new.id::text,
 case when TG_OP='INSERT' then 'CREATE' when old.is_deleted<>new.is_deleted then
   case when new.is_deleted then 'DELETE' else 'RESTORE' end else 'UPDATE' end,
 case when TG_OP='INSERT' then null else to_jsonb(old)-'creation_request_id'-'creation_payload' end,
 to_jsonb(new)-'creation_request_id'-'creation_payload');
 return new;
end; $$;
create trigger tasks_audit after insert or update on public.tasks for each row execute function tasks_private.audit();

create function public.save_task(p_event_id uuid,p_request_id uuid,p_id uuid,p_expected_version bigint,p_fields jsonb)
returns uuid language plpgsql security definer set search_path='' as $$
declare old_row public.tasks; x public.tasks; rid uuid; actor uuid:=auth.uid();
begin
 perform transport_private.authorize(p_event_id,true);
 if p_fields is null or jsonb_typeof(p_fields)<>'object' or exists(
  select 1 from jsonb_object_keys(p_fields) k where k not in ('title','description','assignee_id','priority','due_date_utc','notes')
 ) then raise exception using errcode='22023',message='Invalid task fields'; end if;
 if exists(select 1 from jsonb_each(p_fields) e where e.value<>'null'::jsonb and jsonb_typeof(e.value)<>'string') then
  raise exception using errcode='22023',message='Task fields must be text or null'; end if;
 x:=jsonb_populate_record(null::public.tasks,p_fields);
 if p_id is null then
  if p_request_id is null then raise exception using errcode='22023',message='Request required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_request_id::text,31));
  select * into old_row from public.tasks where creation_request_id=p_request_id;
  if found then
   if old_row.event_id<>p_event_id or old_row.created_by<>actor then raise exception using errcode='42501',message='Not authorized'; end if;
   if old_row.creation_payload is distinct from p_fields then raise exception using errcode='40001',message='Creation payload changed'; end if;
   return old_row.id;
  end if;
 else
  select * into old_row from public.tasks where event_id=p_event_id and id=p_id for update;
  if not found then raise exception using errcode='42501',message='Task unavailable'; end if;
  if old_row.version is distinct from p_expected_version or old_row.is_deleted then raise exception using errcode='40001',message='Task changed'; end if;
 end if;
 -- Preserve existing links when a Person is soft-deleted; forbid new assignment to a deleted Person.
 if x.assignee_id is not null and (p_id is null or x.assignee_id is distinct from old_row.assignee_id) then
  perform 1 from public.people where event_id=p_event_id and id=x.assignee_id and not is_deleted for share;
  if not found then raise exception using errcode='23503',message='Assignee unavailable in this event'; end if;
 end if;
 if p_id is null then
  insert into public.tasks(event_id,creation_request_id,creation_payload,title,description,assignee_id,priority,due_date_utc,notes,created_by,updated_by)
  values(p_event_id,p_request_id,p_fields,x.title,x.description,x.assignee_id,x.priority,x.due_date_utc,x.notes,actor,actor) returning id into rid;
 else
  update public.tasks set title=x.title,description=x.description,assignee_id=x.assignee_id,priority=x.priority,
   due_date_utc=x.due_date_utc,notes=x.notes,version=version+1,updated_at_utc=clock_timestamp(),updated_by=actor
   where event_id=p_event_id and id=p_id returning id into rid;
 end if;
 return rid;
end; $$;

create function public.transition_task(p_event_id uuid,p_id uuid,p_expected_version bigint,p_status text)
returns void language plpgsql security definer set search_path='' as $$
declare t public.tasks;
begin
 perform transport_private.authorize(p_event_id,true);
 select * into t from public.tasks where event_id=p_event_id and id=p_id for update;
 if not found then raise exception using errcode='42501',message='Task unavailable'; end if;
 if t.version is distinct from p_expected_version or t.is_deleted then raise exception using errcode='40001',message='Task changed'; end if;
 if p_status is null or not coalesce(
  (t.status='NEW' and p_status in ('IN_PROGRESS','CANCELLED')) or
  (t.status='IN_PROGRESS' and p_status in ('WAITING','COMPLETED','CANCELLED')) or
  (t.status='WAITING' and p_status in ('IN_PROGRESS','CANCELLED')) or
  (t.status in ('COMPLETED','CANCELLED') and p_status in ('NEW','IN_PROGRESS','WAITING')),false)
 then raise exception using errcode='22023',message='Invalid task transition'; end if;
 update public.tasks set status=p_status,
  completed_at_utc=case when p_status='COMPLETED' then clock_timestamp() else null end,
  cancelled_at_utc=case when p_status='CANCELLED' then clock_timestamp() else null end,
  version=version+1,updated_at_utc=clock_timestamp(),updated_by=auth.uid()
  where event_id=p_event_id and id=p_id;
end; $$;

create function tasks_private.set_deleted(p_event_id uuid,p_id uuid,p_expected_version bigint,p_deleted boolean)
returns void language plpgsql security definer set search_path='' as $$
declare t public.tasks;
begin
 perform transport_private.authorize(p_event_id,true);
 if p_deleted is null then raise exception using errcode='22023',message='Deletion state required'; end if;
 select * into t from public.tasks where event_id=p_event_id and id=p_id for update;
 if not found then raise exception using errcode='42501',message='Task unavailable'; end if;
 if t.version is distinct from p_expected_version then raise exception using errcode='40001',message='Task changed'; end if;
 if t.is_deleted=p_deleted then return; end if;
 update public.tasks set is_deleted=p_deleted,deleted_at_utc=case when p_deleted then clock_timestamp() else null end,
 version=version+1,updated_at_utc=clock_timestamp(),updated_by=auth.uid() where event_id=p_event_id and id=p_id;
end; $$;
create function public.delete_task(p_event_id uuid,p_id uuid,p_expected_version bigint) returns void language sql security definer set search_path='' as $$ select tasks_private.set_deleted(p_event_id,p_id,p_expected_version,true); $$;
create function public.restore_task(p_event_id uuid,p_id uuid,p_expected_version bigint) returns void language sql security definer set search_path='' as $$ select tasks_private.set_deleted(p_event_id,p_id,p_expected_version,false); $$;
create function public.read_task(p_event_id uuid,p_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 perform transport_private.authorize(p_event_id,false);
 select to_jsonb(t)-'creation_request_id'-'creation_payload' into result from public.tasks t where event_id=p_event_id and id=p_id;
 return result;
end; $$;
create function public.list_tasks(p_event_id uuid,p_query text default '',p_deleted boolean default false) returns setof jsonb language plpgsql security definer set search_path='' as $$
begin
 perform transport_private.authorize(p_event_id,false);
 if p_query is null or length(p_query)>200 or p_deleted is null then raise exception using errcode='22023',message='Invalid task filter'; end if;
 return query select to_jsonb(t)-'creation_request_id'-'creation_payload' from public.tasks t
 where event_id=p_event_id and is_deleted=p_deleted and
  (p_query='' or strpos(lower(title),lower(p_query))>0 or strpos(lower(coalesce(description,'')),lower(p_query))>0 or strpos(lower(coalesce(notes,'')),lower(p_query))>0)
 order by due_date_utc nulls last,created_at_utc,id;
end; $$;
create function public.task_assignees(p_event_id uuid) returns setof jsonb language plpgsql security definer set search_path='' as $$
begin
 perform transport_private.authorize(p_event_id,false);
 return query select jsonb_build_object('id',id,'label',concat_ws(' ',first_name,nullif(last_name,'')),'is_deleted',is_deleted)
 from public.people where event_id=p_event_id order by first_name,last_name,id;
end; $$;
revoke all on all functions in schema tasks_private from public,anon,authenticated;
do $$ declare fn regprocedure; begin
 for fn in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in
 ('save_task','transition_task','delete_task','restore_task','read_task','list_tasks','task_assignees') loop
 execute format('revoke all on function %s from public,anon,authenticated',fn);
 execute format('grant execute on function %s to authenticated',fn);
 end loop;
end; $$;
alter publication supabase_realtime add table public.tasks;
commit;
