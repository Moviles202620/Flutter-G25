import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../mock_data/departments.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedDepartment;

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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<AppState>().updateUserProfile(
            name: _nameController.text.trim(),
            department: _selectedDepartment!,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
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
                      child: const Center(
                        child: Text(
                          'FU',
                          style: TextStyle(
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
                          border: Border.all(color: Colors.white, width: 2),
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
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20, color: AppColors.greyText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                    const Icon(Icons.lock_outline, size: 18, color: AppColors.greyText),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name
              const Text(
                'Nombre completo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Ingresa tu nombre',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
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
                    return 'El nombre es obligatorio';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(value)) {
                    return 'El nombre solo puede contener letras';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Department
              const Text(
                'Departamento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.business_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
                  ),
                ),
                items: Departments.all.map((department) {
                  return DropdownMenuItem(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un departamento';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(
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
                    foregroundColor: AppColors.greyText,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
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
