import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';

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

  String? _categoria;
  bool _presencial = true;
  bool _publishing = false;

  DateTime? _fecha;
  TimeOfDay? _hora;
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

  // ── Date / time pickers ───────────────────────────────────────────────────

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
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      helpText: 'FECHA LÍMITE DE POSTULACIÓN',
      builder: _yellowTheme,
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Widget _yellowTheme(BuildContext context, Widget? child) {
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

  // ── Formatters ────────────────────────────────────────────────────────────

  String _formatFecha(DateTime? d) {
    if (d == null) return 'mm/dd/yyyy';
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatHora(TimeOfDay? t) {
    if (t == null) return '--:-- --';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $ampm';
  }

  DateTime _buildDateTime() {
    final base = _fecha ?? DateTime.now();
    final t = _hora ?? TimeOfDay.now();
    return DateTime(base.year, base.month, base.day, t.hour, t.minute);
  }

  // ── Publish ───────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Por favor corrige los errores en el formulario');
      return;
    }
    if (_categoria == null || _categoria!.isEmpty) {
      _showError('Por favor selecciona una categoría');
      return;
    }

    setState(() => _publishing = true);

    final localOffer = OfferModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      requirements: _requirementsCtrl.text.trim(),
      category: _categoria!,
      valueCop: int.tryParse(_valueCtrl.text.trim()) ?? 0,
      dateTime: _buildDateTime(),
      deadline: _deadline,
      durationHours: int.tryParse(_durationCtrl.text.trim()) ?? 0,
      isOnSite: _presencial,
      location: _presencial ? _locationCtrl.text.trim() : '',
    );

    // Capture AppState before the async gap
    final appState = context.read<AppState>();

    OfferModel savedOffer = localOffer;
    String? apiError;

    try {
      savedOffer = await ApiService.createOffer(localOffer);
    } catch (e) {
      apiError = e.toString();
    }

    // Always save locally so the app works offline too
    appState.addOffer(savedOffer);

    // Fire OS banner + add in-app notifications
    NotificationService.onOfferPublished(savedOffer.title);
    appState.onOfferPublished(savedOffer);

    setState(() => _publishing = false);

    if (!mounted) return;

    if (apiError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado localmente. Sin conexión al servidor.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Oferta publicada exitosamente!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final descCounter = '${_descCtrl.text.length} / 1000';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Crear oferta',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  const Text('Detalles de la oferta',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text(
                    'Completa los campos para publicar tu nueva solicitud.',
                    style: TextStyle(
                        fontSize: 16,
                        color: AppColors.greyText,
                        height: 1.25),
                  ),
                  const SizedBox(height: 14),

                  // ── Title + Description ─────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('TÍTULO'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _titleCtrl,
                          maxLength: 80,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
                          ],
                          decoration: _inputDeco('Ejem: Monitoría de Cálculo'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El título es obligatorio';
                            }
                            if (v.trim().length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        _fieldLabel('DESCRIPCIÓN'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descCtrl,
                          maxLength: 1000,
                          maxLines: 5,
                          onChanged: (_) => setState(() {}),
                          decoration: _inputDeco(
                            'Describe las tareas, contexto y lo que\nesperas del postulante...',
                            counterText: '',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'La descripción es obligatoria';
                            }
                            if (v.trim().length < 10) {
                              return 'Mínimo 10 caracteres';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(descCounter,
                              style: const TextStyle(
                                  color: Color(0xFF9AA4B2))),
                        ),
                        const SizedBox(height: 14),

                        // ── Requirements (NEW) ───────────────────────────
                        _fieldLabel('REQUISITOS'),
                        const SizedBox(height: 6),
                        const Text(
                          'Un requisito por línea',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.greyText),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _requirementsCtrl,
                          maxLines: 4,
                          decoration: _inputDeco(
                            'Ejem:\nNota en Cálculo >= 4.0\nDisponibilidad presencial',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Agrega al menos un requisito';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Category ────────────────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('CATEGORÍA'),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _categoria,
                          items: const [
                            DropdownMenuItem(
                                value: 'Académico', child: Text('Académico')),
                            DropdownMenuItem(
                                value: 'Eventos', child: Text('Eventos')),
                            DropdownMenuItem(
                                value: 'Logística',
                                child: Text('Logística')),
                            DropdownMenuItem(
                                value: 'Administrativo',
                                child: Text('Administrativo')),
                          ],
                          onChanged: (v) => setState(() => _categoria = v),
                          decoration: _inputDeco('Selecciona una categoría'),
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Value, date, deadline, duration ─────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('VALOR (COP)'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _valueCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: _inputDeco('60000',
                              prefixText: '\$  '),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El valor es obligatorio';
                            }
                            final n = int.tryParse(v.trim());
                            if (n == null || n <= 0) {
                              return 'Ingresa un valor válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Job date + time
                        Row(
                          children: [
                            Expanded(
                              child: _LabeledField(
                                label: 'FECHA DEL TRABAJO',
                                value: _formatFecha(_fecha),
                                icon: Icons.calendar_month_outlined,
                                onTap: _pickFecha,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledField(
                                label: 'HORA',
                                value: _formatHora(_hora),
                                icon: Icons.access_time_rounded,
                                onTap: _pickHora,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Deadline (NEW)
                        _LabeledField(
                          label: 'FECHA LÍMITE DE POSTULACIÓN',
                          value: _deadline != null
                              ? _formatFecha(_deadline)
                              : 'Sin límite',
                          icon: Icons.event_busy_outlined,
                          onTap: _pickDeadline,
                          isOptional: true,
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel('DURACIÓN ESTIMADA'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _durationCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: _inputDeco('Ejem: 2'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Obligatorio';
                                  }
                                  final n = int.tryParse(v.trim());
                                  if (n == null || n <= 0) {
                                    return 'Valor inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Horas',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.greyText,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Location (on-site toggle + address) ─────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.greyText),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Ubicación presencial',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Switch(
                              value: _presencial,
                              activeThumbColor: AppColors.primaryYellow,
                              onChanged: (v) =>
                                  setState(() => _presencial = v),
                            ),
                          ],
                        ),

                        // Location address field (NEW – only when on-site)
                        if (_presencial) ...[
                          const SizedBox(height: 14),
                          _fieldLabel('DIRECCIÓN / SALÓN'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _locationCtrl,
                            decoration: _inputDeco(
                                'Ejem: Edificio ML, Salón ML-204'),
                            validator: (v) {
                              if (_presencial &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Indica la ubicación presencial';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // ── Sticky publish button ─────────────────────────────────
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _publishing ? null : _publish,
                    child: _publishing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black54,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Publicar oferta',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900)),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward),
                            ],
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

  // ── Small helpers ─────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            letterSpacing: 1.1, fontWeight: FontWeight.w900),
      );

  InputDecoration _inputDeco(
    String hint, {
    String? prefixText,
    String? counterText,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
        prefixText: prefixText,
        counterText: counterText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryYellow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      );
}

// ── Reusable card wrapper ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

// ── Labeled tappable field ────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool isOptional;

  const _LabeledField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.contains('mm/') ||
        value.contains('--') ||
        (isOptional && value == 'Sin límite');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                letterSpacing: 1.1, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: isPlaceholder
                          ? const Color(0xFF9AA4B2)
                          : AppColors.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: AppColors.greyText),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
