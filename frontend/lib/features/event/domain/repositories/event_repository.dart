import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';

abstract interface class EventRepository {
  Future<List<EventEntity>> getEvents({DateTime? from, DateTime? to});
  Future<EventEntity> createEvent(EventEntity event);
  Future<EventEntity> updateEvent(EventEntity event);
  Future<void> deleteEvent(String id);
  Future<List<EventEntity>> getUpcomingEvents({int limit = 5});
  Future<List<EventEntity>> extractEventsFromImage(List<int> imageBytes);
}
