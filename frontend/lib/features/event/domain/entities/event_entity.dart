import 'package:flutter/material.dart';
import 'package:smart_calendar/core/theme/app_theme.dart';

enum EventCategory {
  school,
  personal,
  work,
  health,
  social,
  other;

  String get label {
    switch (this) {
      case EventCategory.personal: return '개인';
      case EventCategory.school: return '학교';
      case EventCategory.work: return '업무';
      case EventCategory.health: return '건강';
      case EventCategory.social: return '소셜';
      case EventCategory.other: return '기타';
    }
  }

  Color get color {
    switch (this) {
      case EventCategory.personal: return AppColors.eventPersonal;
      case EventCategory.school: return AppColors.accentGreen;
      case EventCategory.work: return AppColors.eventWork;
      case EventCategory.health: return AppColors.eventHealth;
      case EventCategory.social: return AppColors.eventSocial;
      case EventCategory.other: return AppColors.eventOther;
    }
  }
}

class EventEntity {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final bool isAllDay;
  final EventCategory category;
  final String? location;
  final String? contactEmail;
  final String? memo;
  final String? link;
  final int? reminderMinutes; // 알림 (분 단위)
  final bool isVerified; // OCR로 자동 수집된 경우

  const EventEntity({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
    this.isAllDay = false,
    this.category = EventCategory.personal,
    this.location,
    this.contactEmail,
    this.memo,
    this.link,
    this.reminderMinutes,
    this.isVerified = false,
  });

  bool get isMultiDay {
    if (endAt == null) return false;
    final start = DateTime(startAt.year, startAt.month, startAt.day);
    final end = DateTime(endAt!.year, endAt!.month, endAt!.day);
    return end.isAfter(start);
  }
}
