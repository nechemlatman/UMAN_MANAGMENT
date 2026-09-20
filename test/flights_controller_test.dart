import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/application/flights_controller.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache;
import 'support/flights_fakes.dart';

void main() {
  test('flights controller lists flights and manages selection', () async {
    final eventRepo = FakeRepository();
    final events = EventController(eventRepo, MemoryCache());
    await events.start();
    
    final repo = FakeFlightsRepository();
    final controller = FlightsController(repo, events);
    
    expect(controller.state.load, FlightsLoad.initial);
    
    await controller.start();
    expect(controller.state.load, FlightsLoad.data);
    expect(controller.state.flights.length, 1);
    expect(controller.state.flights.first.airline, 'El Al');
    
    await controller.selectFlight(flightFixture().id);
    expect(controller.state.selectedFlight?.id, flightFixture().id);
    
    await controller.close();
    await events.close();
  });

  test('flights controller handles errors and offline state', () async {
    final eventRepo = FakeRepository();
    final events = EventController(eventRepo, MemoryCache());
    await events.start();
    
    final repo = FakeFlightsRepository();
    repo.failure = CloudFailureKind.unavailable;
    final controller = FlightsController(repo, events);
    
    await controller.start();
    expect(controller.state.load, FlightsLoad.error);
    expect(controller.state.online, false);
    
    await controller.close();
    await events.close();
  });
}
