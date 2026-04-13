import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../mock_data/departments.dart';
import '../../../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedDepartment;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _selectedDepartment = user?.department ?? Departments.all.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final appState = context.read<AppState>();
    final settings = context.read<SettingsState>();
    final name = _nameController.text.trim();
    final department = _selectedDepartment!;

    appState.updateUserProfile(name: name, department: department);

    final token = appState.authToken;
    if (token != null) {
      try {
        await ApiService.updateUserProfile(token, {
          'name': name,
          'department': department,
          'language': settings.language,
          'is_dark_mode': settings.isDarkMode,
        });
      } on ApiException {
        // Backend sync failed, local update still applied
      }
    }

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('profile_updated')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark ? AppColors.darkModeText : AppColors.darkText;
    final secondary = isDark ? AppColors.darkGreyText : AppColors.greyText;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.t('edit_profile_title'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 12),

              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (user?.name.isNotEmpty == true)
                              ? user!.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
                              : 'FU',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Email (Read-only)
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, size: 20, color: secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.email ?? '',
                        style: TextStyle(fontSize: 16, color: secondary),
                      ),
                    ),
                    Icon(Icons.lock_outline, size: 18, color: secondary),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name
              Text(
                context.t('full_name'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                style: TextStyle(color: textColor),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'),
                  ),
                ],
                decoration: InputDecoration(
                  hintText: context.t('hint_name'),
                  hintStyle: TextStyle(color: secondary),
                  prefixIcon: Icon(Icons.person_outline, color: secondary),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryYellow,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.danger, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.t('err_name_required');
                  }
                  if (value.trim().length < 3) {
                    return context.t('err_name_min');
                  }
                  if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(value)) {
                    return context.t('err_name_letters_only');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Department
              Text(
                context.t('department'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                dropdownColor: surface,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.business_outlined, color: secondary),
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryYellow,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                ),
                items: Departments.all.map((department) {
                  return DropdownMenuItem(
                    value: department,
                    child: Text(department, style: TextStyle(color: textColor)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedDepartment = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.t('err_dept_required');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          context.t('save'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondary,
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.t('cancel'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
