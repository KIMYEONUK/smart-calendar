import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_calendar/features/event/data/repositories/event_repository_impl.dart';
import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';

part 'event_provider.g.dart';

// ─── 월별 이벤트 목록 ─────────────────────────────────────────
@riverpod
class EventNotifier extends _$EventNotifier {
  @override
  Future<List<EventEntity>> build() async {
    final now = DateTime.now();
    return _fetchMonth(now.year, now.month);
  }

  Future<List<EventEntity>> _fetchMonth(int year, int month) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    return ref.read(eventRepositoryProvider).getEvents(from: from, to: to);
  }

  Future<void> loadMonth(int year, int month) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMonth(year, month));
  }

  Future<EventEntity?> createEvent(EventEntity event) async {
    final newEvent =
        await ref.read(eventRepositoryProvider).createEvent(event);
    state = state.whenData((list) => [...list, newEvent]
      ..sort((a, b) => a.startAt.compareTo(b.startAt)));
    return newEvent;
  }

  Future<void> updateEvent(EventEntity event) async {
    final updated =
        await ref.read(eventRepositoryProvider).updateEvent(event);
    state = state.whenData((list) {
      final idx = list.indexWhere((e) => e.id == event.id);
      if (idx == -1) return list;
      final newList = [...list];
      newList[idx] = updated;
      return newList..sort((a, b) => a.startAt.compareTo(b.startAt));
    });
  }

  Future<void> deleteEvent(String id) async {
    await ref.read(eventRepositoryProvider).deleteEvent(id);
    state = state.whenData((list) => list.where((e) => e.id != id).toList());
  }

  Future<List<EventEntity>> extractFromImage(List<int> imageBytes) async {
    return ref
        .read(eventRepositoryProvider)
        .extractEventsFromImage(imageBytes);
  }
}

// ─── 오늘 이벤트만 필터링 ─────────────────────────────────────
@riverpod
List<EventEntity> todayEvents(TodayEventsRef ref) {
  final events = ref.watch(eventNotifierProvider).valueOrNull ?? [];
  final today = DateTime.now();
  return events.where((e) {
    final start = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
    final end = e.endAt != null
        ? DateTime(e.endAt!.year, e.endAt!.month, e.endAt!.day)
        : start;
    final d = DateTime(today.year, today.month, today.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }).toList();
}

// ─── 날짜별 이벤트 맵 ─────────────────────────────────────────
@riverpod
Map<DateTime, List<EventEntity>> eventsByDay(EventsByDayRef ref) {
  final events = ref.watch(eventNotifierProvider).valueOrNull ?? [];
  final map = <DateTime, List<EventEntity>>{};
  for (final e in events) {
    final start = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
    final end = e.endAt != null
        ? DateTime(e.endAt!.year, e.endAt!.month, e.endAt!.day)
        : start;
    var cur = start;
    while (!cur.isAfter(end)) {
      map.putIfAbsent(cur, () => []).add(e);
      cur = cur.add(const Duration(days: 1));
    }
  }
  return map;
}
