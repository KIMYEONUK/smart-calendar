import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarItem {
  final String id;
  final String name;
  final int colorValue;
  final bool isVisible;

  CalendarItem({required this.id, required this.name, required this.colorValue, this.isVisible = true});

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': colorValue, 'visible': isVisible};
  factory CalendarItem.fromJson(Map<String, dynamic> j) =>
      CalendarItem(id: j['id'], name: j['name'], colorValue: j['color'], isVisible: j['visible'] ?? true);
  
  CalendarItem copyWith({bool? isVisible}) =>
      CalendarItem(id: id, name: name, colorValue: colorValue, isVisible: isVisible ?? this.isVisible);
}

class CalendarNotifier extends Notifier<List<CalendarItem>> {
  static const _key = 'user_calendars';

  @override
  List<CalendarItem> build() {
    _load();
    return _defaults();
  }

  List<CalendarItem> _defaults() => [
    CalendarItem(id: 'personal', name: '개인', colorValue: 0xFF4A6CF7),
    CalendarItem(id: 'school',   name: '학교', colorValue: 0xFF52C41A),
    CalendarItem(id: 'work',     name: '업무', colorValue: 0xFFFF6B6B),
    CalendarItem(id: 'health',   name: '건강', colorValue: 0xFFEF4444),
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final saved = (jsonDecode(raw) as List)
          .map((e) => CalendarItem.fromJson(e))
          .toList();
      // 기본 4개 색상은 항상 최신값으로 덮어쓰기
      final defaults = _defaults();
      final merged = saved.map((item) {
        final def = defaults.where((d) => d.id == item.id).firstOrNull;
        if (def != null) {
          return CalendarItem(id: item.id, name: item.name, colorValue: def.colorValue, isVisible: item.isVisible);
        }
        return item;
      }).toList();
      state = merged;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> add(String name, Color color) async {
    final item = CalendarItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorValue: color.value,
    );
    state = [...state, item];
    await _save();
  }

  Future<void> remove(String id) async {
    if (['personal', 'school', 'work', 'health'].contains(id)) return;
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> toggleVisibility(String id) async {
    state = state.map((e) => e.id == id ? e.copyWith(isVisible: !e.isVisible) : e).toList();
    await _save();
  }
}

final calendarProvider =
    NotifierProvider<CalendarNotifier, List<CalendarItem>>(CalendarNotifier.new);
