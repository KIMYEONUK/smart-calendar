import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_calendar/features/event/data/datasources/event_datasource.dart';
import 'package:smart_calendar/features/event/data/models/event_model.dart';
import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';
import 'package:smart_calendar/features/event/domain/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.read(eventDatasourceProvider));
});

class EventRepositoryImpl implements EventRepository {
  final EventDatasource _remote;
  const EventRepositoryImpl(this._remote);

  @override
  Future<List<EventEntity>> getEvents({DateTime? from, DateTime? to}) async {
    final models = await _remote.getEvents(from: from, to: to);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<EventEntity> createEvent(EventEntity event) async {
    final model = await _remote.createEvent(EventModel.fromEntity(event));
    return model.toEntity();
  }

  @override
  Future<EventEntity> updateEvent(EventEntity event) async {
    final model = await _remote.updateEvent(
        event.id, EventModel.fromEntity(event));
    return model.toEntity();
  }

  @override
  Future<void> deleteEvent(String id) => _remote.deleteEvent(id);

  @override
  Future<List<EventEntity>> getUpcomingEvents({int limit = 5}) async {
    final models = await _remote.getUpcomingEvents(limit: limit);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<EventEntity>> extractEventsFromImage(
      List<int> imageBytes) async {
    final models = await _remote.extractEventsFromImage(imageBytes);
    return models.map((m) => m.toEntity()).toList();
  }
}
