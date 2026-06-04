import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_calendar/features/todo/domain/entities/todo_entity.dart';

part 'todo_provider.g.dart';

// ─── Todo Notifier (로컬 상태 — 백엔드 연동 시 교체 가능) ───────
@riverpod
class TodoNotifier extends _$TodoNotifier {
  static const _uuid = Uuid();

  @override
  List<TodoEntity> build() => [];

  void addTodo({required String title, String? description, DateTime? dueDate}) {
    final todo = TodoEntity(
      id: _uuid.v4(),
      title: title,
      description: description,
      isDone: false,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    state = [...state, todo];
  }

  void toggle(String id) {
    state = state
        .map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t)
        .toList();
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}
