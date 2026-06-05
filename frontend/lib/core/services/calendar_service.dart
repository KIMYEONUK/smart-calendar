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
    CalendarItem(id: 'personal', name: '개인', colorValue: 0xFF6366F1),
    CalendarItem(id: 'school',   name: '학교', colorValue: 0xFF10B981),
    CalendarItem(id: 'work',     name: '업무', colorValue: 0xFFF59E0B),
    CalendarItem(id: 'health',   name: '건강', colorValue: 0xFFEF4444),
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => CalendarItem.fromJson(e))
          .toList();
      state = list;
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
