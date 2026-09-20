export async function runFlightsChecks({db,a,b,outsider,equal,denied,identity,scalar}) {
  await identity(a);
  const event = await scalar("select (public.create_event(gen_random_uuid(),'Flight tests',2026,'2026-09-01','2026-09-20','USD')).id::text");
  const other = await scalar("select (public.create_event(gen_random_uuid(),'Other scope',2026,'2026-09-01','2026-09-20','USD')).id::text");
  await db.exec(`reset role; insert into public.event_members(event_id,user_id,created_by) values('${event}','${b}','${a}');`);
  await identity(a);

  const json = obj => "'"+JSON.stringify(obj).replaceAll("'","''")+"'::jsonb";
  const f1_fields = {
    direction: 'INBOUND', airline: 'El Al', flight_number: 'LY001',
    departure_airport: 'JFK', arrival_airport: 'TLV',
    scheduled_departure_utc: '2026-09-21T10:00:00Z',
    scheduled_arrival_utc: '2026-09-21T20:00:00Z',
    status: 'SCHEDULED', is_locked: false
  };
  const f1_request = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
  const create_f1 = `select public.save_flight('${event}','${f1_request}',null,null,${json(f1_fields)})::text`;
  const f1_id = await scalar(create_f1);
  await equal(create_f1, f1_id);
  await equal(`select count(*)::int from public.flights where event_id='${event}'`, 1);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${f1_id}'`, 1);

  // Test Search
  await equal(`select count(*)::int from public.list_flights('${event}', 'El Al')`, 1);
  await equal(`select count(*)::int from public.list_flights('${event}', 'LY001')`, 1);
  await equal(`select count(*)::int from public.list_flights('${event}', 'JFK')`, 1);
  await equal(`select count(*)::int from public.list_flights('${event}', 'Unknown')`, 0);

  // Test Validation Repairs
  await denied(`select public.save_flight('${event}',gen_random_uuid(),null,null,${json({...f1_fields, airline: 'A'.repeat(201)})})`, '22023');
  await denied(`select public.save_flight('${event}',gen_random_uuid(),null,null,${json({...f1_fields, scheduled_departure_utc: '2026-09-21T20:00:00Z', scheduled_arrival_utc: '2026-09-21T10:00:00Z'})})`, '23514');

  // Test Passenger Scoping DEFECT repair
  const p1_fields = {first_name:'David', phone:'123', status:'ACTIVE'};
  const p1_id = await scalar(`select public.save_person('${event}',gen_random_uuid(),null,null,${json(p1_fields)})::text`);

  const p_other_id = await scalar(`select public.save_person('${other}',gen_random_uuid(),null,null,${json(p1_fields)})::text`);
  const f_other_id = await scalar(`select public.save_flight('${other}',gen_random_uuid(),null,null,${json(f1_fields)})::text`);

  const pass_fields = {flight_id: f1_id, person_id: p1_id, status: 'CONFIRMED'};
  const pass_request = 'e1e1e1e1-e1e1-4e1e-8e1e-e1e1e1e1e1e1';
  const create_pass = `select public.save_flight_passenger('${event}','${pass_request}',null,null,${json(pass_fields)})::text`;
  const pass_id = await scalar(create_pass);
  await equal(create_pass, pass_id);

  // CROSS-EVENT INTEGRITY CHECKS (The most important repair verification)
  // Try to add a person from OTHER event to flight in THIS event via RPC.
  // This should fail with FK violation (23503) because the RPC uses the same event_id for all.
  await denied(`select public.save_flight_passenger('${event}',gen_random_uuid(),null,null,${json({...pass_fields, person_id: p_other_id})})`, '23503');
  // Try to add a person from THIS event to flight in OTHER event via RPC.
  await denied(`select public.save_flight_passenger('${event}',gen_random_uuid(),null,null,${json({...pass_fields, flight_id: f_other_id})})`, '23503');

  // Directly try to bypass RPC with mismatched IDs (as superuser/owner roles in test harness)
  await db.exec('reset role;');
  await denied(`insert into public.flight_passengers(event_id, flight_id, person_id, creation_request_id, created_by, updated_by) values('${event}','${f_other_id}','${p1_id}',gen_random_uuid(),'${a}','${a}')`, '23503');
  await identity(b);

  // Test CAS
  await identity(b);
  const update_f1 = (version, fields=f1_fields) => `select public.save_flight('${event}',null,'${f1_id}',${version},${json(fields)})`;
  await equal(`select version::int from public.flights where id='${f1_id}'`, 1);
  await db.exec(update_f1(1, {...f1_fields, airline: 'Updated El Al'}));
  await equal(`select version::int from public.flights where id='${f1_id}'`, 2);
  await denied(update_f1(1), '40001');

  // Test Soft Delete
  await db.exec(`select public.set_flight_deleted('${event}','${f1_id}',2,true)`);
  await equal(`select count(*)::int from public.flights where event_id='${event}' and is_deleted=false`, 0);
  await equal(`select count(*)::int from public.flights where event_id='${event}' and is_deleted=true`, 1);
}
