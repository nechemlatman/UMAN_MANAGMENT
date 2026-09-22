export async function runTransportChecks({db, a, b, outsider, equal, denied, identity, scalar}) {
  await identity(a);
  const event = await scalar("select (public.create_event(gen_random_uuid(),'Transport tests',2026,'2026-09-01','2026-09-20','USD')).id::text");
  const other = await scalar("select (public.create_event(gen_random_uuid(),'Other scope',2026,'2026-09-01','2026-09-20','USD')).id::text");
  await db.exec(`reset role; insert into public.event_members(event_id,user_id,created_by) values('${event}','${b}','${a}');`);
  await identity(a);

  const json = obj => "'" + JSON.stringify(obj).replaceAll("'", "''") + "'::jsonb";

  // --- DRIVERS TEST ---
  const driverFields = {
    full_name: 'Yossi Levi',
    phone_number: '+972 52-999-8877',
    license_number: 'LIC-12345',
    notes: 'Primary driver',
    status: 'ACTIVE'
  };
  const dReq = 'd1111111-1111-4111-8111-111111111111';
  const saveDriver = (req, id, ver, fieldsObj) =>
    `select public.save_driver('${event}', ${req ? `'${req}'` : 'null'}, ${id ? `'${id}'` : 'null'}, ${ver ?? 'null'}, ${json(fieldsObj)})`;

  const driverId = await scalar(saveDriver(dReq, null, null, driverFields));
  await equal(`select count(*)::int from public.drivers where event_id='${event}'`, 1);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${driverId}'`, 1);
  await equal(`select public.read_driver('${event}', '${driverId}')->>'full_name'`, 'Yossi Levi');

  // Idempotent retry
  await equal(saveDriver(dReq, null, null, driverFields), driverId);

  // Search
  await equal(`select count(*)::int from public.list_drivers('${event}', 'Yossi')`, 1);
  await equal(`select count(*)::int from public.list_drivers('${event}', 'Levi')`, 1);
  await equal(`select count(*)::int from public.list_drivers('${event}', '999')`, 1);
  await equal(`select count(*)::int from public.list_drivers('${other}', 'Yossi')`, 0);

  // Update
  await identity(b);
  const updatedDriverFields = { ...driverFields, full_name: 'Yossi Levi Jr', status: 'INACTIVE' };
  await db.exec(saveDriver(null, driverId, 1, updatedDriverFields));
  await equal(`select public.read_driver('${event}', '${driverId}')->>'full_name'`, 'Yossi Levi Jr');
  await equal(`select public.read_driver('${event}', '${driverId}')->>'status'`, 'INACTIVE');
  await equal(`select version::int from public.drivers where id='${driverId}'`, 2);

  // Stale update rejected
  await denied(saveDriver(null, driverId, 1, updatedDriverFields), '40001');

  // Delete
  await db.exec(`select public.delete_driver('${event}', '${driverId}', 2)`);
  await equal(`select count(*)::int from public.list_drivers('${event}')`, 0);
  await equal(`select count(*)::int from public.list_drivers('${event}', '', true)`, 1);

  // --- VEHICLES TEST ---
  await identity(a);
  const vehicleFields = {
    name: 'Sprinter 01',
    vehicle_type: 'VAN',
    license_plate: '12-345-67',
    capacity: 16,
    status: 'AVAILABLE',
    notes: 'Clean Sprinter van'
  };
  const vReq = 'c2222222-2222-4222-8222-222222222222';
  const saveVehicle = (req, id, ver, fieldsObj) =>
    `select public.save_vehicle('${event}', ${req ? `'${req}'` : 'null'}, ${id ? `'${id}'` : 'null'}, ${ver ?? 'null'}, ${json(fieldsObj)})`;

  const vehicleId = await scalar(saveVehicle(vReq, null, null, vehicleFields));
  await equal(`select count(*)::int from public.vehicles where event_id='${event}'`, 1);
  await equal(`select count(*)::int from public.audit_entries where entity_id='${vehicleId}'`, 1);
  await equal(`select public.read_vehicle('${event}', '${vehicleId}')->>'name'`, 'Sprinter 01');
  await equal(`select (public.read_vehicle('${event}', '${vehicleId}')->>'capacity')::int`, 16);

  // Idempotent retry
  await equal(saveVehicle(vReq, null, null, vehicleFields), vehicleId);

  // Validation rejection (capacity < 1)
  await denied(saveVehicle(null, vehicleId, 1, { ...vehicleFields, capacity: 0 }), '22023');

  // Search
  await equal(`select count(*)::int from public.list_vehicles('${event}', 'Sprinter')`, 1);
  await equal(`select count(*)::int from public.list_vehicles('${event}', '345')`, 1);
  await equal(`select count(*)::int from public.list_vehicles('${other}', 'Sprinter')`, 0);

  // Update
  const updatedVehicleFields = { ...vehicleFields, capacity: 19, status: 'MAINTENANCE' };
  await db.exec(saveVehicle(null, vehicleId, 1, updatedVehicleFields));
  await equal(`select (public.read_vehicle('${event}', '${vehicleId}')->>'capacity')::int`, 19);
  await equal(`select public.read_vehicle('${event}', '${vehicleId}')->>'status'`, 'MAINTENANCE');

  // Delete
  await db.exec(`select public.delete_vehicle('${event}', '${vehicleId}', 2)`);
  await equal(`select count(*)::int from public.list_vehicles('${event}')`, 0);
  await equal(`select count(*)::int from public.list_vehicles('${event}', '', true)`, 1);

  // Outsider denial
  await identity(outsider);
  await denied(`select * from public.list_drivers('${event}')`, '42501');
  await denied(`select * from public.list_vehicles('${event}')`, '42501');
}
