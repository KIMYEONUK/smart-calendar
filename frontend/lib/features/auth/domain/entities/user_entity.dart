class UserEntity {
  final String id;
  final String username;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? connectedCalendar;
  final String? profileImage;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.connectedCalendar,
    this.profileImage,
  });
}
