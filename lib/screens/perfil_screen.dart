// ============================================================
// perfil_screen.dart - GymTracker
// Pantalla de perfil: muestra datos visualmente con métricas
// corporales. La edición se abre en un bottom sheet.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _perfil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final perfil = await DatabaseHelper.instance.getPerfil();
    setState(() {
      _perfil = perfil;
      _loading = false;
    });
  }

  double? _calcImc() {
    final peso = (_perfil?['pesoKg'] as num?)?.toDouble();
    final talla = (_perfil?['tallaCm'] as num?)?.toDouble();
    if (peso == null || talla == null || talla <= 0) return null;
    return peso / ((talla / 100) * (talla / 100));
  }

  String _categoriaImc(double imc) {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Peso normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _colorImc(double imc) {
    if (imc < 18.5) return const Color(0xFF2563EB);
    if (imc < 25) return AppTheme.success;
    if (imc < 30) return const Color(0xFFD97706);
    return Colors.red;
  }

  double? _calcPctGrasa() {
    final peso = (_perfil?['pesoKg'] as num?)?.toDouble();
    final talla = (_perfil?['tallaCm'] as num?)?.toDouble();
    final genero = _perfil?['genero'] as String? ?? 'Hombre';
    if (peso == null || talla == null || talla <= 0) return null;
    final imc = peso / ((talla / 100) * (talla / 100));
    final edad = _calcEdad() ?? 30;
    return genero == 'Hombre'
        ? (1.20 * imc) + (0.23 * edad) - 10.8 - 5.4
        : (1.20 * imc) + (0.23 * edad) - 5.4;
  }

  double? _calcMasaMuscular() {
    final peso = (_perfil?['pesoKg'] as num?)?.toDouble();
    final grasa = _calcPctGrasa();
    if (peso == null || grasa == null) return null;
    return peso - (peso * grasa / 100);
  }

  double? _calcPesoIdeal() {
    final talla = (_perfil?['tallaCm'] as num?)?.toDouble();
    final genero = _perfil?['genero'] as String? ?? 'Hombre';
    if (talla == null) return null;
    return genero == 'Hombre'
        ? 50 + 0.91 * (talla - 152.4)
        : 45.5 + 0.91 * (talla - 152.4);
  }

  int? _calcEdad() {
    final fechaStr = _perfil?['fechaNacimiento'] as String?;
    if (fechaStr == null) return null;
    final fecha = DateTime.tryParse(fechaStr);
    if (fecha == null) return null;
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) edad--;
    return edad;
  }

  void _abrirEdicion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarPerfilSheet(
        perfilActual: _perfil,
        onGuardado: _cargar,
      ),
    );
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 400);
    if (picked != null && _perfil != null) {
      await DatabaseHelper.instance
          .savePerfil({..._perfil!, 'fotoPerfil': picked.path});
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nombre = _perfil?['nombre'] as String? ?? '';
    final apellido = _perfil?['apellido'] as String? ?? '';
    final email = _perfil?['email'] as String? ?? '';
    final genero = _perfil?['genero'] as String? ?? '';
    final objetivo = _perfil?['objetivo'] as String? ?? '';
    final foto = _perfil?['fotoPerfil'] as String?;
    final peso = (_perfil?['pesoKg'] as num?)?.toDouble();
    final talla = (_perfil?['tallaCm'] as num?)?.toDouble();
    final edad = _calcEdad();
    final iniciales = nombre.isNotEmpty
        ? nombre[0].toUpperCase() +
            (apellido.isNotEmpty ? apellido[0].toUpperCase() : '')
        : 'G';
    final imc = _calcImc();
    final grasa = _calcPctGrasa();
    final muscular = _calcMasaMuscular();
    final pesoIdeal = _calcPesoIdeal();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            toolbarHeight: 48,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                onPressed: _abrirEdicion,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _cambiarFoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: foto != null
                                  ? ClipOval(child: Image.file(File(foto), fit: BoxFit.cover))
                                  : Center(
                                      child: Text(iniciales,
                                          style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white))),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 13, color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$nombre $apellido'.trim().isEmpty ? 'Sin nombre' : '$nombre $apellido',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(email, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                      ],
                      if (objetivo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(objetivo,
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSeccion(
                  titulo: 'Datos personales',
                  icono: Icons.person_outline,
                  children: [
                    if (genero.isNotEmpty) _fila('Género', genero, Icons.wc_outlined),
                    if (edad != null) _fila('Edad', '$edad años', Icons.cake_outlined),
                    if (peso != null) _fila('Peso actual', '${peso.toStringAsFixed(1)} kg', Icons.monitor_weight_outlined),
                    if (talla != null) _fila('Talla', '${talla.toStringAsFixed(0)} cm', Icons.height),
                    if (objetivo.isNotEmpty) _fila('Objetivo', objetivo, Icons.flag_outlined, isLast: true),
                  ],
                ),

                if (imc != null)
                  _buildSeccion(
                    titulo: 'Métricas corporales',
                    icono: Icons.analytics_outlined,
                    subtitulo: 'Calculadas con fórmulas Deurenberg e IBW',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('IMC', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                Row(
                                  children: [
                                    Text(imc.toStringAsFixed(1),
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _colorImc(imc))),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _colorImc(imc).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(_categoriaImc(imc),
                                          style: TextStyle(fontSize: 11, color: _colorImc(imc), fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 8,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF22C55E), Color(0xFFD97706), Color(0xFFEF4444)],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('15', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
                                Text('18.5', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
                                Text('25', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
                                Text('30', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
                                Text('40', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0x18000000)),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            if (grasa != null)
                              _metricaCard('% Grasa', '${grasa.toStringAsFixed(1)}%',
                                  Icons.water_drop_outlined, const Color(0xFF0EA5E9), const Color(0xFFE0F2FE)),
                            if (grasa != null && muscular != null) const SizedBox(width: 10),
                            if (muscular != null)
                              _metricaCard('Masa muscular', '${muscular.toStringAsFixed(1)} kg',
                                  Icons.fitness_center_outlined, AppTheme.success, AppTheme.successLight),
                            if (muscular != null && pesoIdeal != null) const SizedBox(width: 10),
                            if (pesoIdeal != null)
                              _metricaCard('Peso ideal', '${pesoIdeal.toStringAsFixed(1)} kg',
                                  Icons.scale_outlined, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(
                          '* Valores estimados. No reemplazan evaluación médica profesional.',
                          style: TextStyle(fontSize: 10, color: AppTheme.textHint, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({required String titulo, required IconData icono, String? subtitulo, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18000000), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icono, size: 15, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    if (subtitulo != null)
                      Text(subtitulo, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x18000000)),
          ...children,
        ],
      ),
    );
  }

  Widget _fila(String label, String value, IconData icon, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppTheme.primaryIcon),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0x18000000)),
      ],
    );
  }

  Widget _metricaCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── BOTTOM SHEET EDICIÓN ─────────────────────────────────────
class _EditarPerfilSheet extends StatefulWidget {
  final Map<String, dynamic>? perfilActual;
  final VoidCallback onGuardado;
  const _EditarPerfilSheet({required this.perfilActual, required this.onGuardado});

  @override
  State<_EditarPerfilSheet> createState() => _EditarPerfilSheetState();
}

class _EditarPerfilSheetState extends State<_EditarPerfilSheet> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController();
  String _genero = 'Hombre';
  String _objetivo = 'Ganar músculo';
  DateTime? _fechaNacimiento;
  bool _guardando = false;
  final _objetivos = ['Ganar músculo', 'Perder grasa', 'Mantenimiento', 'Mejorar rendimiento'];

  @override
  void initState() {
    super.initState();
    final p = widget.perfilActual;
    if (p != null) {
      _nombreCtrl.text = p['nombre'] ?? '';
      _apellidoCtrl.text = p['apellido'] ?? '';
      _emailCtrl.text = p['email'] ?? '';
      _pesoCtrl.text = p['pesoKg']?.toString() ?? '';
      _tallaCtrl.text = p['tallaCm']?.toString() ?? '';
      _genero = p['genero'] ?? 'Hombre';
      _objetivo = p['objetivo'] ?? 'Ganar músculo';
      if (p['fechaNacimiento'] != null) {
        _fechaNacimiento = DateTime.tryParse(p['fechaNacimiento']);
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _pesoCtrl.dispose();
    _tallaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await DatabaseHelper.instance.savePerfil({
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'genero': _genero,
      'fechaNacimiento': _fechaNacimiento?.toIso8601String(),
      'pesoKg': double.tryParse(_pesoCtrl.text.replaceAll(',', '.')),
      'tallaCm': double.tryParse(_tallaCtrl.text.replaceAll(',', '.')),
      'objetivo': _objetivo,
      'fotoPerfil': widget.perfilActual?['fotoPerfil'],
    });
    widget.onGuardado();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(hoy.year - 10),
    );
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryIcon, size: 18),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Text('Editar perfil',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const Spacer(),
                TextButton(
                  onPressed: _guardando ? null : _guardar,
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: _guardando
                      ? const SizedBox(height: 14, width: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _nombreCtrl, decoration: _deco('Nombre', Icons.person_outline))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellido'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _deco('Correo electrónico', Icons.mail_outline),
                  ),
                  const SizedBox(height: 16),
                  const Text('Género', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Hombre', 'Mujer'].map((g) {
                      final sel = g == _genero;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _genero = g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: sel ? AppTheme.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(g == 'Hombre' ? Icons.male : Icons.female,
                                      size: 16, color: sel ? Colors.white : AppTheme.textSecondary),
                                  const SizedBox(width: 5),
                                  Text(g, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppTheme.fieldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_outlined, color: AppTheme.primaryIcon, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _fechaNacimiento != null
                                ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
                                : 'Fecha de nacimiento',
                            style: TextStyle(fontSize: 14,
                                color: _fechaNacimiento != null ? AppTheme.textPrimary : AppTheme.textHint),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryIcon, size: 15),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pesoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _deco('Peso (kg)', Icons.monitor_weight_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _tallaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _deco('Talla (cm)', Icons.height),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Objetivo', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _objetivos.map((o) {
                      final sel = o == _objetivo;
                      return GestureDetector(
                        onTap: () => setState(() => _objetivo = o),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                          ),
                          child: Text(o, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: sel ? Colors.white : AppTheme.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
