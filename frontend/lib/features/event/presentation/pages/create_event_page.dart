import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';
import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';
import 'package:smart_calendar/features/event/presentation/providers/event_provider.dart';
import 'package:smart_calendar/core/services/calendar_service.dart';
import 'package:smart_calendar/core/services/calendar_service.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  final DateTime? initialStartAt;
  final DateTime? initialEndAt;
  const CreateEventPage({super.key, this.initialStartAt, this.initialEndAt});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

// 단일 일정 폼 데이터
class _EventForm {
  final String id = const Uuid().v4();
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final memoCtrl = TextEditingController();
  final linkCtrl = TextEditingController();
  DateTime startAt = DateTime.now().add(const Duration(hours: 1));
  DateTime? endAt;
  bool isAllDay = false;
  EventCategory category = EventCategory.personal;
  int? reminderMinutes;

  void dispose() {
    titleCtrl.dispose();
    locationCtrl.dispose();
    emailCtrl.dispose();
    memoCtrl.dispose();
    linkCtrl.dispose();
  }
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<_EventForm> _forms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final form = _EventForm();
    if (widget.initialStartAt != null) form.startAt = widget.initialStartAt!;
    if (widget.initialEndAt != null) form.endAt = widget.initialEndAt;
    _forms = [form];
  }

  @override
  void dispose() {
    for (final f in _forms) f.dispose();
    super.dispose();
  }

  void _addForm() {
    setState(() => _forms.add(_EventForm()));
  }

  void _removeForm(int idx) {
    if (_forms.length == 1) return;
    setState(() {
      _forms[idx].dispose();
      _forms.removeAt(idx);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      for (final f in _forms) {
        final event = EventEntity(
          id: f.id,
          title: f.titleCtrl.text.trim(),
          startAt: f.startAt,
          endAt: f.endAt,
          isAllDay: f.isAllDay,
          category: f.category,
          location: f.locationCtrl.text.trim().isEmpty
              ? null
              : f.locationCtrl.text.trim(),
          contactEmail: f.emailCtrl.text.trim().isEmpty
              ? null
              : f.emailCtrl.text.trim(),
          memo: f.memoCtrl.text.trim().isEmpty ? null : f.memoCtrl.text.trim(),
          link: f.linkCtrl.text.trim().isEmpty ? null : f.linkCtrl.text.trim(),
          reminderMinutes: f.reminderMinutes,
        );
        await ref
            .read(eventNotifierProvider.notifier)
            .createEvent(event);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        title: Text(
          '일정 추가',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    '저장',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            // ── 동시 등록 안내 ─────────────────────────
            if (_forms.length > 1)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${_forms.length}개의 일정을 한 번에 등록합니다',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // ── 각 일정 폼 ────────────────────────────
            ...List.generate(_forms.length, (i) {
              return _EventFormCard(
                key: ValueKey(_forms[i].id),
                form: _forms[i],
                index: i,
                total: _forms.length,
                onRemove: () => _removeForm(i),
                onUpdate: () => setState(() {}),
              );
            }),

            // ── 일정 추가 버튼 ────────────────────────
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('일정 하나 더 추가'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 단일 일정 폼 카드 ─────────────────────────────────────────
class _EventFormCard extends StatefulWidget {
  final _EventForm form;
  final int index;
  final int total;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;

  const _EventFormCard({
    super.key,
    required this.form,
    required this.index,
    required this.total,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_EventFormCard> createState() => _EventFormCardState();
}

class _EventFormCardState extends State<_EventFormCard> {
  bool _expanded = true;

  Future<void> _pickDate(bool isStart) async {
    final f = widget.form;
    final initial = isStart ? f.startAt : (f.endAt ?? f.startAt);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    if (!f.isAllDay) {
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (timePicked == null) return;
      final combined = DateTime(
          picked.year, picked.month, picked.day,
          timePicked.hour, timePicked.minute);
      setState(() {
        if (isStart) {
          f.startAt = combined;
        } else {
          f.endAt = combined;
        }
      });
    } else {
      setState(() {
        if (isStart) {
          f.startAt = picked;
        } else {
          f.endAt = picked;
        }
      });
    }
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final f = widget.form;
    final fmt = f.isAllDay ? 'yyyy.MM.dd' : 'yyyy.MM.dd HH:mm';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          // ── 헤더 ───────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                          color: cs.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.titleCtrl.text.isEmpty
                          ? '일정 제목을 입력해주세요'
                          : f.titleCtrl.text,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: f.titleCtrl.text.isEmpty
                            ? cs.onSurfaceVariant
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.total > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          size: 20),
                      color: AppColors.accent,
                      onPressed: widget.onRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 제목 (필수) ───────────────────
                  TextFormField(
                    controller: f.titleCtrl,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
                    decoration: InputDecoration(
                      labelText: '제목 *',
                      prefixIcon: Icon(Icons.title_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 종일 토글 ────────────────────
                  Row(
                    children: [
                      const Icon(Icons.all_inclusive_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('종일', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      Switch(
                        value: f.isAllDay,
                        onChanged: (v) => setState(() => f.isAllDay = v),
                        activeColor: cs.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── 날짜/시간 ─────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: '시작',
                          value: DateFormat(fmt).format(f.startAt),
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateButton(
                          label: '종료 (선택)',
                          value: f.endAt != null
                              ? DateFormat(fmt).format(f.endAt!)
                              : '—',
                          onTap: () => _pickDate(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── 캘린더 선택 ──────────────────
                  Text('캘린더', style: theme.textTheme.labelLarge
                      ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (ctx, ref, _) {
                      final calendars = ref.watch(calendarProvider);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: calendars.map((cal) {
                          final selected = f.category.name == cal.id ||
                              (f.category == EventCategory.personal && cal.id == 'personal');
                          return GestureDetector(
                            onTap: () => setState(() {
                              f.category = EventCategory.values.firstWhere(
                                (e) => e.name == cal.id,
                                orElse: () => EventCategory.personal,
                              );
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? cal.color : cal.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cal.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : cal.color,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── 장소 (선택) ───────────────────
                  TextFormField(
                    controller: f.locationCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '장소 (선택)',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          size: 20, color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 연락처 (이메일) ───────────────
                  TextFormField(
                    controller: f.emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '연락처 (이메일, 선택)',
                      prefixIcon: Icon(Icons.alternate_email_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 알림 ─────────────────────────
                  DropdownButtonFormField<int?>(
                    value: f.reminderMinutes,
                    hint: Text('알림 설정 (선택)',
                        style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.notifications_outlined,
                          size: 20, color: cs.onSurfaceVariant),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('알림 없음')),
                      DropdownMenuItem(value: 0, child: Text('정시')),
                      DropdownMenuItem(value: 5, child: Text('5분 전')),
                      DropdownMenuItem(value: 15, child: Text('15분 전')),
                      DropdownMenuItem(value: 30, child: Text('30분 전')),
                      DropdownMenuItem(value: 60, child: Text('1시간 전')),
                      DropdownMenuItem(value: 1440, child: Text('1일 전')),
                    ],
                    onChanged: (v) => setState(() => f.reminderMinutes = v),
                  ),
                  const SizedBox(height: 12),

                  // ── 메모 ─────────────────────────
                  TextFormField(
                    controller: f.memoCtrl,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '메모 (선택)',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 44),
                        child: Icon(Icons.notes_rounded,
                            size: 20, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 링크 ─────────────────────────
                  TextFormField(
                    controller: f.linkCtrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: '링크 (선택)',
                      prefixIcon: Icon(Icons.link_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Date Button ───────────────────────────────────────────────
class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
