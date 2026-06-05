import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_calendar/core/router/app_router.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';
import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';
import 'package:smart_calendar/features/event/presentation/providers/event_provider.dart';
import 'package:smart_calendar/features/event/presentation/widgets/event_card.dart';
import 'package:smart_calendar/features/event/presentation/widgets/fab_speed_dial.dart';
import 'package:smart_calendar/core/services/holiday_service.dart';
import 'package:smart_calendar/core/services/calendar_service.dart';
import 'package:smart_calendar/features/settings/presentation/pages/settings_page.dart';
import 'package:smart_calendar/features/auth/presentation/providers/auth_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late TabController _tabController;
  DateTime? _dragStart;
  DateTime? _dragEnd;
  bool _isDragging = false;
  final _calendarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTypeSheet(BuildContext context, DateTime start, DateTime end) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(color: Colors.transparent)),
          Center(
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AddTypeItem(icon: Icons.calendar_today_outlined, label: '일정', onTap: () { Navigator.pop(ctx); context.push(AppRoutes.createEvent, extra: {'startAt': start, 'endAt': end}); }),
                    _AddTypeItem(icon: Icons.check_box_outlined, label: '할일', onTap: () => Navigator.pop(ctx)),
                    _AddTypeItem(icon: Icons.loop_outlined, label: '습관', onTap: () => Navigator.pop(ctx)),
                    _AddTypeItem(icon: Icons.swap_horiz_outlined, label: '구간', onTap: () { Navigator.pop(ctx); context.push(AppRoutes.createEvent, extra: {'startAt': start, 'endAt': end}); }),
                    _AddTypeItem(icon: Icons.horizontal_rule_outlined, label: '마스킹 테이프', onTap: () => Navigator.pop(ctx)),
                    _AddTypeItem(icon: Icons.grid_view_outlined, label: '배경', onTap: () => Navigator.pop(ctx)),
                    _AddTypeItem(icon: Icons.crop_square_outlined, label: '테두리', onTap: () => Navigator.pop(ctx)),
                    _AddTypeItem(icon: Icons.tag_outlined, label: '날짜 태그', onTap: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDaySheet(BuildContext context, DateTime day) {
    final allEvents = ref.read(eventNotifierProvider).valueOrNull ?? [];
    final events = allEvents.where((e) {
      final d = DateTime(day.year, day.month, day.day);
      final start = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
      if (!e.isMultiDay) return start == d;
      final end = DateTime(e.endAt!.year, e.endAt!.month, e.endAt!.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
    final monthKey = '${day.year}-${day.month.toString().padLeft(2, "0")}';
    final holidays = ref.read(holidayProvider(monthKey)).valueOrNull ?? {};
    final service = ref.read(holidayServiceProvider);
    final holName = service.getName(day, holidays);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) {
          final scrollController = ScrollController();
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          return Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(DateFormat("M월 d일 (E)", "ko").format(day), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),

                      if (holName != null) ...[
                        const SizedBox(width: 8),
                        Text(holName, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () { Navigator.pop(ctx); context.push(AppRoutes.createEvent, extra: {'startAt': _selectedDay, 'endAt': _selectedDay}); },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("일정 추가"),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: events.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.event_available_rounded, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          Text("일정이 없어요", style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ]))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: events.length,
                          itemBuilder: (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: EventCard(
                              event: events[i],
                              onTap: () { Navigator.pop(ctx); context.push(AppRoutes.eventDetail(events[i].id)); },
                              onDelete: () { Navigator.pop(ctx); ref.read(eventNotifierProvider.notifier).deleteEvent(events[i].id); },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
      },
    );
  }

  List<EventEntity> _ongoingEvents(List<EventEntity> all) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return all.where((e) {
      if (!e.isMultiDay) return false;
      final start = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
      final end = DateTime(e.endAt!.year, e.endAt!.month, e.endAt!.day);
      return !today.isBefore(start) && !today.isAfter(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final monthKey = '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, "0")}';
    final holidayAsync = ref.watch(holidayProvider(monthKey));
    final holidays = holidayAsync.valueOrNull ?? {};
    final service = ref.read(holidayServiceProvider);
    final eventsByDay = ref.watch(eventsByDayProvider);
    final eventsAsync = ref.watch(eventNotifierProvider);
    final allEvents = eventsAsync.valueOrNull ?? [];
    final ongoing = _ongoingEvents(allEvents);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('yyyy년 M월', 'ko').format(_focusedDay),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: cs.onSurface),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(text: '월간 캘린더'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('진행 중'),
                  if (ongoing.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text('${ongoing.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NaverCalendarView(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            holidays: holidays,
            holidayService: service,
            eventsByDay: eventsByDay,
            allEvents: allEvents,
            isLoading: eventsAsync.isLoading,
            onDaySelected: (day) {
              setState(() { _selectedDay = day; _focusedDay = day; });
              _showDaySheet(context, day);
            },
            onLongPressStart: (day) {
              setState(() { _dragStart = day; _dragEnd = day; _isDragging = true; });
            },
            onLongPressMoveUpdate: (day) {
              if (_dragStart != null) setState(() => _dragEnd = day);
            },
            onLongPressEnd: (day) {
              setState(() => _isDragging = false);
              if (_dragStart != null && _dragEnd != null) {
                final start = _dragStart!.isBefore(_dragEnd!) ? _dragStart! : _dragEnd!;
                final end = _dragStart!.isBefore(_dragEnd!) ? _dragEnd! : _dragStart!;
                _showAddTypeSheet(context, start, end);
              }
              setState(() { _dragStart = null; _dragEnd = null; });
            },
            dragStart: _dragStart,
            dragEnd: _dragEnd,
            calendarKey: _calendarKey,
            onMonthChanged: (day) {
              setState(() => _focusedDay = day);
              ref.read(eventNotifierProvider.notifier).loadMonth(day.year, day.month);
            },
            onEventTap: (e) => context.push(AppRoutes.eventDetail(e.id)),
            onEventDelete: (e) => ref.read(eventNotifierProvider.notifier).deleteEvent(e.id),
            onAddEvent: () => context.push(AppRoutes.createEvent, extra: {'startAt': _selectedDay, 'endAt': _selectedDay}),
          ),
          ongoing.isEmpty ? _EmptyOngoingState() : _OngoingCheckList(events: ongoing),
        ],
      ),
      drawer: _CalendarDrawer(),
      floatingActionButton: FabSpeedDial(
        onAddEvent: () => context.push(AppRoutes.createEvent, extra: {'startAt': _selectedDay, 'endAt': _selectedDay}),
        onOcr: () => context.push(AppRoutes.ocrScan),
      ),
    );
  }
}

class _NaverCalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<String, String> holidays;
  final HolidayService holidayService;
  final Map<DateTime, List<EventEntity>> eventsByDay;
  final List<EventEntity> allEvents;
  final bool isLoading;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<EventEntity> onEventTap;
  final ValueChanged<EventEntity> onEventDelete;
  final VoidCallback onAddEvent;
  final ValueChanged<DateTime> onLongPressStart;
  final ValueChanged<DateTime> onLongPressMoveUpdate;
  final ValueChanged<DateTime> onLongPressEnd;
  final DateTime? dragStart;
  final DateTime? dragEnd;
  final GlobalKey? calendarKey;

  const _NaverCalendarView({
    required this.focusedDay,
    required this.selectedDay,
    required this.holidays,
    required this.holidayService,
    required this.eventsByDay,
    required this.allEvents,
    required this.isLoading,
    required this.onDaySelected,
    required this.onMonthChanged,
    required this.onEventTap,
    required this.onEventDelete,
    required this.onAddEvent,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
    this.dragStart,
    this.dragEnd,
    this.calendarKey,
  });

  List<EventEntity> _getEventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return allEvents.where((e) {
      final start = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
      if (!e.isMultiDay) return start == d;
      final end = DateTime(e.endAt!.year, e.endAt!.month, e.endAt!.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Map<String, _MultiDaySlot> _buildMultiDayLayout(DateTime calStart, int totalCells) {
    final slots = <String, _MultiDaySlot>{};
    final multiDay = allEvents.where((e) => e.isMultiDay).toList();
    for (int week = 0; week < 6; week++) {
      final weekStart = calStart.add(Duration(days: week * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final laneUsed = <int, String>{};
      for (final e in multiDay) {
        final eStart = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
        final eEnd = DateTime(e.endAt!.year, e.endAt!.month, e.endAt!.day);
        if (eEnd.isBefore(weekStart) || eStart.isAfter(weekEnd)) continue;
        final displayStart = eStart.isBefore(weekStart) ? weekStart : eStart;
        final displayEnd = eEnd.isAfter(weekEnd) ? weekEnd : eEnd;
        final startCol = displayStart.difference(weekStart).inDays;
        final endCol = displayEnd.difference(weekStart).inDays;
        final span = endCol - startCol + 1;
        int lane = 0;
        while (laneUsed[lane] != null) lane++;
        laneUsed[lane] = e.id;
        slots["${e.id}_w$week"] = _MultiDaySlot(
          event: e, week: week, startCol: startCol, span: span, lane: lane,
          continuesLeft: eStart.isBefore(weekStart),
          continuesRight: eEnd.isAfter(weekEnd),
        );
      }
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final firstOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final startOffset = firstOfMonth.weekday % 7;
    final calStart = firstOfMonth.subtract(Duration(days: startOffset));
    const totalCells = 42;
    final multiDayLayout = _buildMultiDayLayout(calStart, totalCells);
    final selectedEventsForDay = _getEventsForDay(selectedDay);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: ["일","월","화","수","목","금","토"].asMap().entries.map((e) {
              final isWeekend = e.key == 0 || e.key == 6;
              return Expanded(
                child: Center(
                  child: Text(e.value, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isWeekend ? AppColors.accent : cs.onSurfaceVariant,
                  )),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: PageController(initialPage: 1200),
            onPageChanged: (page) {
              final newMonth = DateTime(DateTime.now().year, DateTime.now().month + (page - 1200));
              onMonthChanged(newMonth);
            },
            itemBuilder: (ctx, page) {
              final monthOffset = page - 1200;
              final now = DateTime.now();
              final pageMonth = DateTime(now.year, now.month + monthOffset);
              final pageFirstOfMonth = DateTime(pageMonth.year, pageMonth.month, 1);
              final pageStartOffset = pageFirstOfMonth.weekday % 7;
              final pageCalStart = pageFirstOfMonth.subtract(Duration(days: pageStartOffset));
              final pageMultiDayLayout = _buildMultiDayLayout(pageCalStart, 42);
              return Padding(
                key: calendarKey,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildCalendarGrid(context, pageCalStart, 42, pageMultiDayLayout, pageMonth),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, DateTime calStart, int totalCells, Map<String, _MultiDaySlot> multiDayLayout, [DateTime? overrideMonth]) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final currentMonth = overrideMonth ?? focusedDay;

    return Column(
      children: List.generate(6, (week) {
        final weekDays = List.generate(7, (col) => calStart.add(Duration(days: week * 7 + col)));
        final weekSlots = multiDayLayout.values.where((s) => s.week == week).toList()
          ..sort((a, b) => a.lane.compareTo(b.lane));
        final maxLane = weekSlots.isEmpty ? 0 : weekSlots.map((s) => s.lane).reduce((a, b) => a > b ? a : b) + 1;
        final multiDayHeight = maxLane * 18.0;

        return Expanded(child: Column(
          children: [
            Expanded(
              child: Row(
                children: weekDays.map((day) {
                  final isThisMonth = day.month == currentMonth.month && day.year == currentMonth.year;
                  final isToday = DateTime(day.year, day.month, day.day) == todayKey;
                  final isSelected = DateTime(day.year, day.month, day.day) == DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  final isHol = holidayService.isHoliday(day, holidays);
                  final holName = holidayService.getName(day, holidays);
                  final isSun = day.weekday == 7;
                  final isSat = day.weekday == 6;
                  final isRed = isHol || isSun;

                  Color textColor;
                  if (!isThisMonth) textColor = cs.onSurfaceVariant.withValues(alpha: 0.3);
                  else if (isRed) textColor = Colors.red;
                  else if (isSat) textColor = AppColors.accent;
                  else textColor = cs.onSurface;

                  final d = DateTime(day.year, day.month, day.day);
                  final isInDragRange = dragStart != null && dragEnd != null && (
                    (d.isAfter(dragStart!) || d == dragStart!) &&
                    (d.isBefore(dragEnd!) || d == dragEnd!) ||
                    (d.isAfter(dragEnd!) || d == dragEnd!) &&
                    (d.isBefore(dragStart!) || d == dragStart!)
                  );

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        onDaySelected(day);
                        if (day.month != focusedDay.month) onMonthChanged(day);
                      },
                      onLongPressStart: (_) => onLongPressStart(day),
                      onLongPressMoveUpdate: (details) {
                        if (calendarKey?.currentContext == null) return;
                        final box = calendarKey!.currentContext!.findRenderObject() as RenderBox;
                        final local = box.globalToLocal(details.globalPosition);
                        final totalW = box.size.width;
                        final totalH = box.size.height;
                        final col = (local.dx / (totalW / 7)).floor().clamp(0, 6);
                        final row = (local.dy / (totalH / 6)).floor().clamp(0, 5);
                        final newDay = calStart.add(Duration(days: row * 7 + col));
                        onLongPressMoveUpdate(newDay);
                      },
                      onLongPressEnd: (_) => onLongPressEnd(day),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (holName != null && isThisMonth)
                            Text(holName, style: const TextStyle(fontSize: 6, color: Colors.red, height: 1), maxLines: 1, overflow: TextOverflow.ellipsis)
                          else
                            const SizedBox(height: 7),
                          Container(
                            width: 24, height: 24,
                            decoration: isSelected
                                ? BoxDecoration(color: isRed ? Colors.red : cs.primary, shape: BoxShape.circle)
                                : isToday
                                    ? BoxDecoration(color: cs.primary.withValues(alpha: 0.15), shape: BoxShape.circle)
                                    : isInDragRange
                                        ? BoxDecoration(color: Colors.blue.withValues(alpha: 0.3), shape: BoxShape.circle)
                                        : null,
                            child: Center(
                              child: Text("${day.day}", style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected ? Colors.white : isToday ? (isRed ? Colors.red : cs.primary) : textColor,
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (multiDayHeight > 0)
              SizedBox(
                height: multiDayHeight,
                child: Stack(
                  children: weekSlots.map((slot) {
                    final cellWidth = (MediaQuery.of(context).size.width - 4) / 7;
                    final left = slot.startCol * cellWidth + (slot.continuesLeft ? 0 : 2);
                    final width = slot.span * cellWidth - (slot.continuesLeft ? 0 : 2) - (slot.continuesRight ? 0 : 2);
                    final top = slot.lane * 18.0 + 2;
                    return Positioned(
                      left: left, top: top, width: width, height: 15,
                      child: GestureDetector(
                        onTap: () => onEventTap(slot.event),
                        child: Container(
                          decoration: BoxDecoration(
                            color: slot.event.category.color,
                            borderRadius: BorderRadius.horizontal(
                              left: slot.continuesLeft ? Radius.zero : const Radius.circular(4),
                              right: slot.continuesRight ? Radius.zero : const Radius.circular(4),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              if (slot.continuesLeft) const Icon(Icons.arrow_left, size: 10, color: Colors.white),
                              Expanded(child: Text(slot.event.title, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (slot.continuesRight) const Icon(Icons.arrow_right, size: 10, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            _SingleDayBadges(weekDays: weekDays, eventsByDay: eventsByDay, focusedMonth: focusedDay.month, onEventTap: onEventTap),
            if (week < 5) const Divider(height: 1, thickness: 0.5),
          ],
        ));
      }),
    );
  }
}

class _MultiDaySlot {
  final EventEntity event;
  final int week, startCol, span, lane;
  final bool continuesLeft, continuesRight;
  _MultiDaySlot({required this.event, required this.week, required this.startCol, required this.span, required this.lane, required this.continuesLeft, required this.continuesRight});
}

class _SingleDayBadges extends StatelessWidget {
  final List<DateTime> weekDays;
  final Map<DateTime, List<EventEntity>> eventsByDay;
  final int focusedMonth;
  final ValueChanged<EventEntity> onEventTap;
  const _SingleDayBadges({required this.weekDays, required this.eventsByDay, required this.focusedMonth, required this.onEventTap});

  @override
  Widget build(BuildContext context) {
    bool hasAny = false;
    for (final day in weekDays) {
      final key = DateTime(day.year, day.month, day.day);
      if ((eventsByDay[key] ?? []).any((e) => !e.isMultiDay)) { hasAny = true; break; }
    }
    if (!hasAny) return const SizedBox.shrink();
    const maxRows = 2;
    final rows = <Widget>[];
    for (int row = 0; row < maxRows; row++) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weekDays.map((day) {
          final key = DateTime(day.year, day.month, day.day);
          final events = (eventsByDay[key] ?? []).where((e) => !e.isMultiDay).toList();
          final isThisMonth = day.month == focusedMonth;
          if (row >= events.length) return const Expanded(child: SizedBox(height: 16));
          final e = events[row];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              child: GestureDetector(
                onTap: () => onEventTap(e),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: isThisMonth ? e.category.color : e.category.color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(e.title, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          );
        }).toList(),
      ));
    }
    return Padding(padding: const EdgeInsets.only(bottom: 2), child: Column(children: rows));
  }
}

class _OngoingCheckList extends StatefulWidget {
  final List<EventEntity> events;
  const _OngoingCheckList({required this.events});
  @override
  State<_OngoingCheckList> createState() => _OngoingCheckListState();
}

class _OngoingCheckListState extends State<_OngoingCheckList> {
  final Map<String, Set<int>> _checked = {};

  List<String> _parseItems(EventEntity e) {
    final items = <String>[];
    items.add('${DateFormat("M.d").format(e.startAt)} ~ ${DateFormat("M.d").format(e.endAt!)}  기간');
    if (e.memo != null && e.memo!.isNotEmpty) {
      final parts = e.memo!.split(RegExp(r"[,\n]"));
      for (final p in parts) { final t = p.trim(); if (t.isNotEmpty) items.add(t); }
    }
    if (e.location != null && e.location!.isNotEmpty) items.add("장소: ${e.location}");
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: widget.events.length,
      itemBuilder: (ctx, i) {
        final e = widget.events[i];
        final color = e.category.color;
        final remaining = e.endAt!.difference(DateTime.now()).inDays + 1;
        final items = _parseItems(e);
        final checked = _checked[e.id] ?? {};
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(e.title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: remaining <= 7 ? AppColors.accent.withValues(alpha: 0.12) : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("D-$remaining", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: remaining <= 7 ? AppColors.accent : color)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isDone = checked.contains(idx);
                  return InkWell(
                    onTap: () => setState(() {
                      final s = _checked.putIfAbsent(e.id, () => {});
                      if (isDone) s.remove(idx); else s.add(idx);
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: isDone ? color : cs.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDone ? cs.onSurfaceVariant.withValues(alpha: 0.5) : cs.onSurface,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyOngoingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pending_actions_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text("진행 중인 일정이 없어요", style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("기간이 있는 일정이 여기에 표시돼요", style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CalendarDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = ref.watch(authNotifierProvider).valueOrNull;
    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : "?",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? "", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(user?.username ?? "", style: theme.textTheme.bodySmall),
                    ],
                  )),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("내 캘린더", style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  Icon(Icons.add_rounded, color: cs.onSurfaceVariant, size: 20),
                ],
              ),
            ),
            _CalendarList(),
            const Divider(height: 24),
            const Spacer(),
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text("로그아웃", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
                final notifier = ref.read(authNotifierProvider.notifier);
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("로그아웃"),
                    content: const Text("정말 로그아웃 하시겠어요?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("로그아웃", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  notifier.logout();
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _CalendarList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendars = ref.watch(calendarProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        ...calendars.map((cal) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: GestureDetector(
            onTap: () => ref.read(calendarProvider.notifier).toggleVisibility(cal.id),
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: cal.isVisible ? cal.color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: cal.color, width: 2),
              ),
              child: cal.isVisible ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
          ),
          title: Text(cal.name, style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: cal.isVisible ? null : cs.onSurfaceVariant,
          )),
          onTap: () => ref.read(calendarProvider.notifier).toggleVisibility(cal.id),
          trailing: ["personal","school","work","health"].contains(cal.id) ? null
              : GestureDetector(
                  onTap: () => ref.read(calendarProvider.notifier).remove(cal.id),
                  child: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
                ),
        )),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(Icons.add_rounded, color: cs.primary, size: 18),
          title: Text("캘린더 추가", style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          onTap: () => _showAddCalendar(context, ref),
        ),
      ],
    );
  }

  void _showAddCalendar(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    Color selected = const Color(0xFF6366F1);
    final colors = [const Color(0xFF6366F1), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF3B82F6), const Color(0xFFEC4899), const Color(0xFF8B5CF6), const Color(0xFF14B8A6)];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text("캘린더 추가", style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: controller, decoration: InputDecoration(hintText: "캘린더 이름", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
              const SizedBox(height: 16),
              Text("색상", style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(spacing: 10, children: colors.map((c) => GestureDetector(
                onTap: () => setState(() => selected = c),
                child: Container(width: 32, height: 32, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: selected == c ? Border.all(color: Colors.black, width: 3) : null)),
              )).toList()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      ref.read(calendarProvider.notifier).add(controller.text.trim(), selected);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: selected, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("추가", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTypeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddTypeItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }
}
