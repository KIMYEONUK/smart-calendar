import 'package:json_annotation/json_annotation.dart';
import 'package:smart_calendar/features/event/domain/entities/event_entity.dart';

part 'event_model.g.dart';

@JsonSerializable()
class EventModel {
  final String id;
  final String title;

  @JsonKey(name: 'start_at')
  final String startAt;

  @JsonKey(name: 'end_at')
  final String? endAt;

  @JsonKey(name: 'is_all_day', defaultValue: false)
  final bool isAllDay;

  @JsonKey(name: 'category', defaultValue: 'personal')
  final String category;

  final String? location;

  @JsonKey(name: 'contact_email')
  final String? contactEmail;

  final String? memo;
  final String? link;

  @JsonKey(name: 'reminder_minutes')
  final int? reminderMinutes;

  @JsonKey(name: 'is_verified', defaultValue: false)
  final bool isVerified;

  const EventModel({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
    required this.isAllDay,
    required this.category,
    this.location,
    this.contactEmail,
    this.memo,
    this.link,
    this.reminderMinutes,
    required this.isVerified,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  EventEntity toEntity() {
    final cat = EventCategory.values.firstWhere(
      (e) => e.name == category,
      orElse: () => EventCategory.personal,
    );
    return EventEntity(
      id: id,
      title: title,
      startAt: _parseLocal(startAt),
      endAt: endAt != null ? _parseLocal(endAt!) : null,
      isAllDay: isAllDay,
      category: cat,
      location: location,
      contactEmail: contactEmail,
      memo: memo,
      link: link,
      reminderMinutes: reminderMinutes,
      isVerified: isVerified,
    );
  }

  static DateTime _parseLocal(String s) {
    // 타임존 정보 없으면 로컬 시간으로 그대로 파싱
    if (s.endsWith('Z') || s.contains('+')) {
      return DateTime.parse(s).toLocal();
    }
    return DateTime.parse(s);
  }

  static Map<String, dynamic> fromEntity(EventEntity e) => {
        'title': e.title,
        'start_at': e.startAt.toUtc().toIso8601String(),
        if (e.endAt != null) 'end_at': e.endAt!.toUtc().toIso8601String(),
        'is_all_day': e.isAllDay,
        'category': e.category.name,
        if (e.location != null) 'location': e.location,
        if (e.contactEmail != null) 'contact_email': e.contactEmail,
        if (e.memo != null) 'memo': e.memo,
        if (e.link != null) 'link': e.link,
        if (e.reminderMinutes != null) 'reminder_minutes': e.reminderMinutes,
      };
}
