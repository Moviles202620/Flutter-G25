import 'user_profile_model.dart';

class AuthSessionModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserProfileModel user;

  AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: UserProfileModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
