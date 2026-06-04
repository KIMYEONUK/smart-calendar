import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';
import 'package:smart_calendar/features/todo/domain/entities/todo_entity.dart';
import 'package:smart_calendar/features/todo/presentation/providers/todo_provider.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoNotifierProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final pending = todos.where((t) => !t.isDone).toList();
    final done = todos.where((t) => t.isDone).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'To-Do',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: todos.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(
                    label: '할 일',
                    count: pending.length,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  ...pending.map((t) => _TodoItem(
                        todo: t,
                        onToggle: () => ref
                            .read(todoNotifierProvider.notifier)
                            .toggle(t.id),
                        onDelete: () => ref
                            .read(todoNotifierProvider.notifier)
                            .remove(t.id),
                      )),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(
                    label: '완료됨',
                    count: done.length,
                    color: AppColors.accentGreen,
                  ),
                  const SizedBox(height: 8),
                  ...done.map((t) => _TodoItem(
                        todo: t,
                        onToggle: () => ref
                            .read(todoNotifierProvider.notifier)
                            .toggle(t.id),
                        onDelete: () => ref
                            .read(todoNotifierProvider.notifier)
                            .remove(t.id),
                      )),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddTodoSheet(
        onAdd: (title, desc, due) =>
            ref.read(todoNotifierProvider.notifier).addTodo(
                  title: title,
                  description: desc,
                  dueDate: due,
                ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

class _TodoItem extends StatelessWidget {
  final TodoEntity todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoItem({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDone = todo.isDone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.accent),
        ),
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.accentGreen
                        : Colors.transparent,
                    border: Border.all(
                      color: isDone
                          ? AppColors.accentGreen
                          : cs.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone ? cs.onSurfaceVariant : null,
                        ),
                      ),
                      if (todo.description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          todo.description!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (todo.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('M월 d일').format(todo.dueDate!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: todo.dueDate!
                                        .isBefore(DateTime.now())
                                    ? AppColors.accent
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded,
              size: 60,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('할 일이 없어요',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('+ 버튼으로 To-Do를 추가해보세요',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Add Sheet ─────────────────────────────────────────────────
class _AddTodoSheet extends StatefulWidget {
  final void Function(String title, String? desc, DateTime? due) onAdd;
  const _AddTodoSheet({required this.onAdd});

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '할 일 *',
              prefixIcon: Icon(Icons.check_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: '메모 (선택)',
              prefixIcon: Icon(Icons.notes_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate != null
                        ? DateFormat('M월 d일').format(_dueDate!)
                        : '마감일 설정 (선택)',
                    style: TextStyle(
                      color: _dueDate != null
                          ? null
                          : cs.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                  if (_dueDate != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final title = _titleCtrl.text.trim();
              if (title.isEmpty) return;
              widget.onAdd(title, _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(), _dueDate);
              Navigator.pop(context);
            },
            child: const Text('추가하기'),
          ),
        ],
      ),
    );
  }
}
