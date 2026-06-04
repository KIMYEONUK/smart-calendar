import 'package:json_annotation/json_annotation.dart';
import 'package:smart_calendar/features/auth/domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String username;
  final String email;
  final String name;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  @JsonKey(name: 'connected_calendar')
  final String? connectedCalendar;

  @JsonKey(name: 'profile_image')
  final String? profileImage;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.connectedCalendar,
    this.profileImage,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() => UserEntity(
        id: id,
        username: username,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        connectedCalendar: connectedCalendar,
        profileImage: profileImage,
      );
}
