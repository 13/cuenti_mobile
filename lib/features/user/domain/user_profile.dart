import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    int? id,
    @Default('') String username,
    @Default('') String email,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('EUR') String defaultCurrency,
    @Default(true) bool darkMode,
    @Default('de-DE') String locale,
    @Default(false) bool apiEnabled,
    @Default(<String>{}) Set<String> roles,
    int? defaultVehicleCategoryId,
  }) = _UserProfile;

  const UserProfile._();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  bool get isAdmin => roles.contains('ROLE_ADMIN');
}
