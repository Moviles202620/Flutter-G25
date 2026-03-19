import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';

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

  late String? _categoria;
  late bool _presencial;
  bool _saving = false;

  DateTime? _fecha;
  TimeOfDay? _hora;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _titleCtrl = TextEditingController(text: o.title);
    _descCtrl = TextEditingController(text: o.description);
    _requirementsCtrl = TextEditingController(text: o.requirements);
    _valueCtrl = TextEditingController(text: o.valueCop.toString());
    _durationCtrl = TextEditingController(text: o.durationHours.toString());
    _locationCtrl = TextEditingController(text: o.location);
    _categoria = o.category;
    _presencial = o.isOnSite;
    _fecha = o.dateTime;
    _hora = TimeOfDay.fromDateTime(o.dateTime);
    _deadline = o.deadline;
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

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: _yellowTheme,
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
      builder: _yellowTheme,
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: _yellowTheme,
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Widget _yellowTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: AppColors.primaryYellow,
            ),
      ),
      child: child!,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoria == null) return;

    setState(() => _saving = true);

    final dateTime = DateTime(
      _fecha!.year,
      _fecha!.month,
      _fecha!.day,
      _hora?.hour ?? 0,
      _hora?.minute ?? 0,
    );

    final fields = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'requirements': _requirementsCtrl.text.trim(),
      'category': _categoria,
      'value_cop': int.tryParse(_valueCtrl.text.trim()) ?? 0,
      'date_time': dateTime.toIso8601String(),
      'duration_hours': int.tryParse(_durationCtrl.text.trim()) ?? 1,
      'is_on_site': _presencial,
      'location': _locationCtrl.text.trim(),
    };
    if (_deadline != null) {
      fields['deadline'] = _deadline!.toIso8601String();
    }

    try {
      final updated = await ApiService.updateOffer(widget.offer.id, fields);
      if (mounted) {
        context.read<AppState>().updateOffer(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('offer_updated')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        surfaceTintColor: appBarBg,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _field(context.t('title'), _titleCtrl, surfaceColor, borderColor),
            _field(context.t('description'), _descCtrl, surfaceColor,
                borderColor,
                maxLines: 3),
            _field(context.t('requirements'), _requirementsCtrl, surfaceColor,
                borderColor,
                maxLines: 3),
            // Category dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonFormField<String>(
                value: _categoria,
                decoration: InputDecoration(
                  labelText: context.t('category'),
                  border: InputBorder.none,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Académico', child: Text('Académico')),
                  DropdownMenuItem(
                      value: 'Administrativo', child: Text('Administrativo')),
                  DropdownMenuItem(
                      value: 'Investigación', child: Text('Investigación')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => _categoria = v),
              ),
            ),
            _field(context.t('value_cop'), _valueCtrl, surfaceColor,
                borderColor,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),
            _field(context.t('duration_hours'), _durationCtrl, surfaceColor,
                borderColor,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),

            // Date, time & deadline row
            Row(
              children: [
                Expanded(
                  child: _dateButton(
                    context.t('date'),
                    _fecha != null
                        ? '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'
                        : '--',
                    _pickFecha,
                    surfaceColor,
                    borderColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateButton(
                    'Hora',
                    _hora != null
                        ? '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}'
                        : '--',
                    _pickHora,
                    surfaceColor,
                    borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _dateButton(
              context.t('deadline_label'),
              _deadline != null
                  ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                  : '--',
              _pickDeadline,
              surfaceColor,
              borderColor,
            ),
            const SizedBox(height: 14),

            // On-site switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _presencial
                      ? context.t('on_site')
                      : context.t('remote'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                value: _presencial,
                activeColor: AppColors.primaryYellow,
                onChanged: (v) => setState(() => _presencial = v),
              ),
            ),
            const SizedBox(height: 14),

            if (_presencial)
              _field(context.t('location'), _locationCtrl, surfaceColor,
                  borderColor),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: SizedBox(
          height: 58,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.black),
                  )
                : Text(
                    context.t('save'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    Color surface,
    Color border, {
    int maxLines = 1,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primaryYellow, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _dateButton(String label, String value, VoidCallback onTap,
      Color surface, Color border) {
    return GestureDetector(
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
            Text(label,
                style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
