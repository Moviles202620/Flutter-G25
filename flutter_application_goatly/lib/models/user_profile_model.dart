class UserProfileModel {
  final int id;
  final String name;
  final String email;
  final String department;
  final String role;
  final String language;
  final bool isDarkMode;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.language,
    required this.isDarkMode,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> j) =>
      UserProfileModel(
        id: j['id'] as int,
        name: j['name'] as String,
        email: j['email'] as String,
        department: j['department'] as String,
        role: j['role'] as String,
        language: j['language'] as String,
        isDarkMode: j['is_dark_mode'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'department': department,
        'language': language,
        'is_dark_mode': isDarkMode,
      };
}
