import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/offer_model.dart';

class StaffCreateOfferFormPage extends StatefulWidget {
  const StaffCreateOfferFormPage({super.key});

  @override
  State<StaffCreateOfferFormPage> createState() => _StaffCreateOfferFormPageState();
}

class _StaffCreateOfferFormPageState extends State<StaffCreateOfferFormPage> {
  final _descCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String? _categoria;
  bool _presencial = true;

  DateTime? _fecha;
  TimeOfDay? _hora;

  @override
  void dispose() {
    _descCtrl.dispose();
    _titleCtrl.dispose();
    _valueCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _hora = picked);
  }

  String _formatFecha(DateTime? d) {
    if (d == null) return 'mm/dd/yyyy';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$mm/$dd/$yy';
  }

  String _formatHora(TimeOfDay? t) {
    if (t == null) return '--:-- --';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $ampm';
  }

  DateTime _buildDateTimeOrNow() {
    final base = _fecha ?? DateTime.now();
    final t = _hora ?? TimeOfDay.now();
    return DateTime(base.year, base.month, base.day, t.hour, t.minute);
  }

  int _parseCop(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  int _parseDuration(String s) {
    return int.tryParse(s.trim()) ?? 0;
  }

  void _publish() {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final cat = _categoria ?? '';
    final value = _parseCop(_valueCtrl.text);
    final dur = _parseDuration(_durationCtrl.text);
    final dt = _buildDateTimeOrNow();

    if (title.isEmpty || desc.isEmpty || cat.isEmpty || value <= 0 || dur <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa título, descripción, categoría, valor y duración.')),
      );
      return;
    }

    context.read<AppState>().addOffer(
      OfferModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: cat,
        valueCop: value,
        dateTime: dt,
        durationHours: dur,
        isOnSite: _presencial,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final counter = '${_descCtrl.text.length} / 1000';

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
        title: const Text('Crear oferta', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                const Text('Detalles de la oferta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                  'Completa los campos para publicar tu nueva\nsolicitud.',
                  style: TextStyle(fontSize: 16, color: AppColors.greyText, height: 1.25),
                ),
                const SizedBox(height: 14),

                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TÍTULO', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ejem: Monitoría de Cálculo',
                          hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('DESCRIPCIÓN', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descCtrl,
                        maxLength: 1000,
                        maxLines: 6,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Describe las tareas, requisitos y lo que\nesperas del postulante...',
                          hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(counter, style: const TextStyle(color: Color(0xFF9AA4B2))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CATEGORÍA', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _categoria,
                        items: const [
                          DropdownMenuItem(value: 'Académico', child: Text('Académico')),
                          DropdownMenuItem(value: 'Eventos', child: Text('Eventos')),
                          DropdownMenuItem(value: 'Logística', child: Text('Logística')),
                          DropdownMenuItem(value: 'Administrativo', child: Text('Administrativo')),
                        ],
                        onChanged: (v) => setState(() => _categoria = v),
                        decoration: InputDecoration(
                          hintText: 'Selecciona una categoría',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VALOR (COP)', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: '\$  ',
                          hintText: '60000',
                          hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'FECHA',
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

                      const Text('DURACIÓN ESTIMADA', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ejem: 2',
                                hintStyle: const TextStyle(color: Color(0xFF9AA4B2)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Horas', style: TextStyle(fontSize: 18, color: AppColors.greyText, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                _Card(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.greyText),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Ubicación presencial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      Switch(
                        value: _presencial,
                        activeThumbColor: AppColors.primaryYellow,
                        onChanged: (v) => setState(() => _presencial = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _publish,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Publicar oferta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _LabeledField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.contains('mm/') || value.contains('--');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
                      color: isPlaceholder ? const Color(0xFF9AA4B2) : AppColors.darkText,
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
