class TodoEntity {
  final String id;
  final String title;
  final String? description;
  final bool isDone;
  final DateTime? dueDate;
  final DateTime createdAt;

  const TodoEntity({
    required this.id,
    required this.title,
    this.description,
    required this.isDone,
    this.dueDate,
    required this.createdAt,
  });

  TodoEntity copyWith({bool? isDone}) => TodoEntity(
        id: id,
        title: title,
        description: description,
        isDone: isDone ?? this.isDone,
        dueDate: dueDate,
        createdAt: createdAt,
      );
}
