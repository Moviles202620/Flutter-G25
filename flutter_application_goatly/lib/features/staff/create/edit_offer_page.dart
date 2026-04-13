import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';
import '../../../utils/offer_form_utils.dart';

const _kValidCategories = [
  'Academico',
  'Administrativo',
  'Investigacion',
  'Otro',
];

class EditOfferPage extends StatefulWidget {
  final OfferModel offer;

  const EditOfferPage({super.key, required this.offer});

  @override
  State<EditOfferPage> createState() => _EditOfferPageState();
}

class _EditOfferPageState extends State<EditOfferPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _requirementsCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _locationCtrl;

  late String? _category;
  late bool _isOnSite;
  bool _saving = false;

  DateTime? _jobDate;
  TimeOfDay? _jobTime;
  DateTime? _deadline;

  /// Normalizes category from any stored variant to the canonical key.
  /// Returns null if the value isn't a recognised category (safe for DropdownButtonFormField).
  String? _normalizeCategory(String? value) {
    switch (value) {
      case 'Academico':
      case 'Académico':
      case 'Academic':
        return 'Academico';
      case 'Administrativo':
      case 'Administrative':
        return 'Administrativo';
      case 'Investigacion':
      case 'Investigación':
      case 'Research':
        return 'Investigacion';
      case 'Otro':
      case 'Other':
        return 'Otro';
      default:
        // If it happens to match a valid category exactly, use it.
        // Otherwise map to null so the dropdown shows empty (no crash).
        if (value != null && _kValidCategories.contains(value)) return value;
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final offer = widget.offer;
    _titleCtrl = TextEditingController(text: offer.title);
    _descCtrl = TextEditingController(text: offer.description);
    _requirementsCtrl = TextEditingController(text: offer.requirements);
    _valueCtrl = TextEditingController(text: offer.valueCop.toString());
    _durationCtrl = TextEditingController(text: offer.durationHours.toString());
    _locationCtrl = TextEditingController(text: offer.location);
    _category = _normalizeCategory(offer.category);
    _isOnSite = offer.isOnSite;
    _jobDate = offer.dateTime;
    _jobTime = TimeOfDay.fromDateTime(offer.dateTime);
    _deadline = offer.deadline;
  }

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
    final initialDate = _jobDate != null && _jobDate!.isAfter(firstAllowedDate)
        ? _jobDate!
        : firstAllowedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
    final firstAllowedDate = DateTime(now.year, now.month, now.day);
    final initialDate =
        _deadline != null && _deadline!.isAfter(firstAllowedDate)
            ? _deadline!
            : firstAllowedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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

    setState(() => _saving = true);

    final fields = <String, dynamic>{
      'title': normalizeOfferTitle(_titleCtrl.text),
      'description': _descCtrl.text.trim(),
      'requirements': _requirementsCtrl.text.trim(),
      'category': _category,
      'value_cop': int.tryParse(_valueCtrl.text.trim()) ?? 0,
      'date_time': scheduledDateTime.toIso8601String(),
      'duration_hours': int.tryParse(_durationCtrl.text.trim()) ?? 1,
      'is_on_site': _isOnSite,
      'location': _isOnSite ? _locationCtrl.text.trim() : '',
      'deadline': _deadline?.toIso8601String(),
    };

    try {
      final updated = await ApiService.updateOffer(widget.offer.id, fields);
      if (!mounted) return;
      context.read<AppState>().updateOffer(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('offer_updated')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          context.t('edit_offer'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _Section(
              surface: surface,
              border: border,
              child: Column(
                children: [
                  _buildField(
                    controller: _titleCtrl,
                    label: context.t('title'),
                    hint: context.t('hint_title'),
                    validator: (v) => validateOfferTitleLocalized(v, context.t),
                    surface: surface,
                    border: border,
                    maxLength: 80,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _descCtrl,
                    label: context.t('description'),
                    hint: context.t('hint_update_description'),
                    validator: (v) => validateDescriptionLocalized(v, context.t),
                    surface: surface,
                    border: border,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _requirementsCtrl,
                    label: context.t('requirements'),
                    hint: context.t('hint_update_requirements'),
                    validator: (v) => validateRequirementsLocalized(v, context.t),
                    surface: surface,
                    border: border,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
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
            _Section(
              surface: surface,
              border: border,
              child: Column(
                children: [
                  _buildField(
                    controller: _valueCtrl,
                    label: context.t('value_cop'),
                    hint: context.t('hint_value'),
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _durationCtrl,
                    label: context.t('duration_hours'),
                    hint: context.t('hint_duration'),
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerCard(
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickerCard(
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
                  _PickerCard(
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
                  const SizedBox(height: 14),
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
                    _buildField(
                      controller: _locationCtrl,
                      label: context.t('location'),
                      hint: context.t('hint_location'),
                      validator: (value) {
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saving ? null : _save,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color surface,
    required Color border,
    required String? Function(String?) validator,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final Color surface;
  final Color border;

  const _Section({
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _PickerCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color surface;
  final Color border;
  final Color secondary;

  const _PickerCard({
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
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
