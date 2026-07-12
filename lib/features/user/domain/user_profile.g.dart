// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: (json['id'] as num?)?.toInt(),
  username: json['username'] as String? ?? '',
  email: json['email'] as String? ?? '',
  firstName: json['firstName'] as String? ?? '',
  lastName: json['lastName'] as String? ?? '',
  defaultCurrency: json['defaultCurrency'] as String? ?? 'EUR',
  darkMode: json['darkMode'] as bool? ?? true,
  locale: json['locale'] as String? ?? 'de-DE',
  apiEnabled: json['apiEnabled'] as bool? ?? false,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
      const <String>{},
  defaultVehicleCategoryId: (json['defaultVehicleCategoryId'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'defaultCurrency': instance.defaultCurrency,
      'darkMode': instance.darkMode,
      'locale': instance.locale,
      'apiEnabled': instance.apiEnabled,
      'roles': instance.roles.toList(),
      'defaultVehicleCategoryId': instance.defaultVehicleCategoryId,
    };
