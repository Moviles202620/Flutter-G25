import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/offer_form_utils.dart';

class StaffCreateOfferFormPage extends StatefulWidget {
  const StaffCreateOfferFormPage({super.key});

  @override
  State<StaffCreateOfferFormPage> createState() =>
      _StaffCreateOfferFormPageState();
}

class _StaffCreateOfferFormPageState extends State<StaffCreateOfferFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? _category;
  bool _isOnSite = true;
  bool _publishing = false;
  DateTime? _jobDate;
  TimeOfDay? _jobTime;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _requirementsCtrl.dispose();
    _valueCtrl.dispose();
    _durationCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickJobDate() async {
    final now = DateTime.now();
    final firstAllowedDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _jobDate ?? firstAllowedDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(now.year + 3),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _jobDate = picked);
  }

  Future<void> _pickJobTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jobTime ?? TimeOfDay.now(),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _jobTime = picked);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: AppColors.primaryYellow,
          onPrimary: Colors.black,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) {
      _showError(context.t('err_form_errors'));
      return;
    }
    if (_category == null || _category!.isEmpty) {
      _showError(context.t('err_select_category'));
      return;
    }

    final scheduleError = validateScheduledDateTimeLocalized(
      date: _jobDate,
      time: _jobTime,
      t: context.t,
    );
    if (scheduleError != null) {
      _showError(scheduleError);
      return;
    }

    final scheduledDateTime = buildScheduledDateTime(
      date: _jobDate,
      time: _jobTime,
    );
    if (scheduledDateTime == null) {
      _showError(context.t('err_datetime_required'));
      return;
    }

    setState(() => _publishing = true);

    final localOffer = OfferModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: normalizeOfferTitle(_titleCtrl.text),
      description: _descCtrl.text.trim(),
      requirements: _requirementsCtrl.text.trim(),
      category: _category!,
      valueCop: int.tryParse(_valueCtrl.text.trim()) ?? 0,
      dateTime: scheduledDateTime,
      deadline: _deadline,
      durationHours: int.tryParse(_durationCtrl.text.trim()) ?? 0,
      isOnSite: _isOnSite,
      location: _isOnSite ? _locationCtrl.text.trim() : '',
      createdAt: DateTime.now(),
    );

    final appState = context.read<AppState>();
    OfferModel savedOffer = localOffer;
    String? apiError;
    var shouldPersistLocally = true;
    final token = appState.authToken;

    try {
      if (token == null) {
        throw const ApiException('Sesion expirada. Inicia sesion de nuevo.');
      }
      savedOffer = await ApiService.createOffer(localOffer, token);
    } catch (error) {
      apiError = error.toString();
      if (error is ApiException) {
        shouldPersistLocally = false;
      }
    }

    if (shouldPersistLocally) {
      appState.addOffer(savedOffer);
      NotificationService.onOfferPublished(savedOffer.title);
      appState.onOfferPublished(savedOffer);

      // When offline, queue the creation for background sync on reconnect.
      if (apiError != null && token != null) {
        await CacheService.enqueuePendingOp({
          'id': 'offline_offer_${savedOffer.id}',
          'method': 'POST',
          'endpoint': '/offers',
          'token': token,
          'body': savedOffer.toJson(),
          // Extra metadata so AppState can reconstruct the OfferModel locally
          // (toJson omits id/created_at since the backend generates them)
          'local_id': savedOffer.id,
          'local_created_at': savedOffer.createdAt.toIso8601String(),
        });
      }
    }

    if (!mounted) return;
    setState(() => _publishing = false);

    if (apiError != null && shouldPersistLocally) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('saved_locally')),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (apiError != null) {
      _showError(apiError);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t('offer_published')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime? date, {required String nullLabel}) {
    if (date == null) return nullLabel;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay? time, {required String nullLabel}) {
    if (time == null) return nullLabel;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minutes $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final secondary = isDark ? AppColors.darkGreyText : AppColors.greyText;
    final textColor = isDark ? AppColors.darkModeText : AppColors.darkText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        title: Text(
          context.t('create_offer'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              Text(
                context.t('offer_details'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.t('offer_subtitle'),
                style: TextStyle(color: secondary, height: 1.25),
              ),
              const SizedBox(height: 16),
              _FormSection(
                surface: surface,
                border: border,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _titleCtrl,
                      label: context.t('title'),
                      hint: context.t('hint_title'),
                      maxLength: 80,
                      validator: (v) => validateOfferTitleLocalized(v, context.t),
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _descCtrl,
                      label: context.t('description'),
                      hint: context.t('hint_description'),
                      maxLines: 4,
                      maxLength: 1000,
                      validator: (v) => validateDescriptionLocalized(v, context.t),
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _requirementsCtrl,
                      label: context.t('requirements'),
                      hint: context.t('hint_requirements'),
                      maxLines: 4,
                      validator: (v) => validateRequirementsLocalized(v, context.t),
                      surface: surface,
                      border: border,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                surface: surface,
                border: border,
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: surface,
                  style: TextStyle(color: textColor, fontSize: 16),
                  decoration: _inputDecoration(
                    label: context.t('category'),
                    hint: context.t('hint_select_category'),
                    surface: surface,
                    border: border,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'Academico',
                      child: Text(
                        context.t('cat_academic'),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Administrativo',
                      child: Text(
                        context.t('cat_administrative'),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Investigacion',
                      child: Text(
                        context.t('cat_research'),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Otro',
                      child: Text(
                        context.t('cat_other'),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                surface: surface,
                border: border,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _valueCtrl,
                      label: context.t('value_cop'),
                      hint: context.t('hint_value'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.t('err_value_required');
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return context.t('err_value_invalid');
                        }
                        return null;
                      },
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _durationCtrl,
                      label: context.t('duration_label'),
                      hint: context.t('hint_duration'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.t('err_duration_required');
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return context.t('err_duration_invalid');
                        }
                        return null;
                      },
                      surface: surface,
                      border: border,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerField(
                            label: context.t('job_date'),
                            value: _formatDate(
                              _jobDate,
                              nullLabel: context.t('select_date'),
                            ),
                            icon: Icons.calendar_month_outlined,
                            onTap: _pickJobDate,
                            surface: surface,
                            border: border,
                            secondary: secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PickerField(
                            label: context.t('time'),
                            value: _formatTime(
                              _jobTime,
                              nullLabel: context.t('select_time'),
                            ),
                            icon: Icons.access_time_rounded,
                            onTap: _pickJobTime,
                            surface: surface,
                            border: border,
                            secondary: secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PickerField(
                      label: context.t('deadline_label'),
                      value: _formatDate(
                        _deadline,
                        nullLabel: context.t('no_deadline_label'),
                      ),
                      icon: Icons.event_busy_outlined,
                      onTap: _pickDeadline,
                      surface: surface,
                      border: border,
                      secondary: secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                surface: surface,
                border: border,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isOnSite,
                      activeThumbColor: AppColors.primaryYellow,
                      title: Text(
                        _isOnSite
                            ? context.t('on_site')
                            : context.t('remote'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        _isOnSite
                            ? context.t('on_site_subtitle')
                            : context.t('remote_subtitle'),
                        style: TextStyle(color: secondary),
                      ),
                      onChanged: (value) => setState(() => _isOnSite = value),
                    ),
                    if (_isOnSite) ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _locationCtrl,
                        label: context.t('location'),
                        hint: context.t('hint_location'),
                        validator: (value) {
                          if (!_isOnSite) return null;
                          if (value == null || value.trim().isEmpty) {
                            return context.t('err_location_required');
                          }
                          return null;
                        },
                        surface: surface,
                        border: border,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _publishing ? null : _publish,
            child: _publishing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    context.t('create_offer'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color surface,
    required Color border,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        surface: surface,
        border: border,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required Color surface,
    required Color border,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primaryYellow,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final Widget child;
  final Color surface;
  final Color border;

  const _FormSection({
    required this.child,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color surface;
  final Color border;
  final Color secondary;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.surface,
    required this.border,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryYellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
