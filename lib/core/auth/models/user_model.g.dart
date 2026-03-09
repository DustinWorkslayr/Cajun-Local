// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  isActive: json['is_active'] as bool,
  role: json['role'] as String,
  profile: json['profile'] == null
      ? null
      : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'is_active': instance.isActive,
      'role': instance.role,
      'profile': instance.profile,
    };

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  displayName: json['display_name'] as String?,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
    };
