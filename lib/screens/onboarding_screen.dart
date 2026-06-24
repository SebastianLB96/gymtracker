// ============================================================
// onboarding_screen.dart - GymTracker
// Onboarding de 5 pasos activado desde "Regístrate" en Login.
// Paso 1: Correo y contraseña
// Paso 2: Nombre y apellido
// Paso 3: Datos físicos (género, fecha, peso, talla)
// Paso 4: Objetivo
// Paso 5: Resumen con métricas calculadas
// Al finalizar guarda el perfil y regresa al Login.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _paginaActual = 0;

  // Controladores
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _genero = 'Hombre';
  DateTime? _fechaNacimiento;
  String _objetivo = 'Ganar músculo';
  bool _guardando = false;

  final _objetivos = [
    {'label': 'Ganar músculo', 'icon': Icons.fitness_center},
    {'label': 'Perder grasa', 'icon': Icons.local_fire_department_outlined},
    {'label': 'Mantenimiento', 'icon': Icons.balance_outlined},
    {'label': 'Mejorar rendimiento', 'icon': Icons.speed_outlined},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _pesoCtrl.dispose();
    _tallaCtrl.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_paginaActual < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finalizar();
    }
  }

  void _anterior() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool get _puedeAvanzar {
    switch (_paginaActual) {
      case 0:
        return _emailCtrl.text.trim().isNotEmpty &&
            _passCtrl.text.length >= 6 &&
            _passCtrl.text == _confirmPassCtrl.text;
      case 1:
        return _nombreCtrl.text.trim().isNotEmpty;
      case 2:
        return _pesoCtrl.text.isNotEmpty && _tallaCtrl.text.isNotEmpty;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return true;
    }
  }

  String get _errorPaso0 {
    if (_emailCtrl.text.isEmpty && _passCtrl.text.isEmpty) return '';
    if (_passCtrl.text.isNotEmpty && _passCtrl.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (_confirmPassCtrl.text.isNotEmpty &&
        _passCtrl.text != _confirmPassCtrl.text) {
      return 'Las contraseñas no coinciden';
    }
    return '';
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

  Future<void> _finalizar() async {
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
    });
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada! Inicia sesión para continuar.'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ── MÉTRICAS ────────────────────────────────────────────
  double? get _imc {
    final peso = double.tryParse(_pesoCtrl.text);
    final talla = double.tryParse(_tallaCtrl.text);
    if (peso == null || talla == null || talla <= 0) return null;
    return peso / ((talla / 100) * (talla / 100));
  }

  String get _categoriaImc {
    final imc = _imc;
    if (imc == null) return '';
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Peso normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color get _colorImc {
    final imc = _imc;
    if (imc == null) return AppTheme.textSecondary;
    if (imc < 18.5) return const Color(0xFF2563EB);
    if (imc < 25) return AppTheme.success;
    if (imc < 30) return const Color(0xFFD97706);
    return Colors.red;
  }

  double? get _pctGrasa {
    final peso = double.tryParse(_pesoCtrl.text);
    final talla = double.tryParse(_tallaCtrl.text);
    if (peso == null || talla == null || talla <= 0) return null;
    final imc = peso / ((talla / 100) * (talla / 100));
    final edad = _edad ?? 30;
    return _genero == 'Hombre'
        ? (1.20 * imc) + (0.23 * edad) - 10.8 - 5.4
        : (1.20 * imc) + (0.23 * edad) - 5.4;
  }

  double? get _pesoIdeal {
    final talla = double.tryParse(_tallaCtrl.text);
    if (talla == null) return null;
    return _genero == 'Hombre'
        ? 50 + 0.91 * (talla - 152.4)
        : 45.5 + 0.91 * (talla - 152.4);
  }

  int? get _edad {
    if (_fechaNacimiento == null) return null;
    final hoy = DateTime.now();
    int edad = hoy.year - _fechaNacimiento!.year;
    if (hoy.month < _fechaNacimiento!.month ||
        (hoy.month == _fechaNacimiento!.month &&
            hoy.day < _fechaNacimiento!.day)) edad--;
    return edad;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildProgreso(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _paginaActual = i),
              children: [
                _buildPaso1(),
                _buildPaso2(),
                _buildPaso3(),
                _buildPaso4(),
                _buildPaso5(),
              ],
            ),
          ),
          _buildNavegacion(),
        ],
      ),
    );
  }

  // ── BARRA DE PROGRESO ──────────────────────────────────
  Widget _buildProgreso() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    const Text('GymTracker',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark)),
                  ],
                ),
                Text('Paso ${_paginaActual + 1} de 5',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _paginaActual
                          ? AppTheme.primary
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── PASO 1: CORREO Y CONTRASEÑA ────────────────────────
  Widget _buildPaso1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.fitness_center,
                  size: 42, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text('¡Bienvenido a GymTracker! 💪',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Crea tu cuenta para empezar a registrar\ntu progreso en el gimnasio.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Icons.mail_outline,
                  color: AppTheme.primaryIcon, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: 'Mínimo 6 caracteres',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.primaryIcon, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirm,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.primaryIcon, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textHint,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          if (_errorPaso0.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorPaso0,
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── PASO 2: NOMBRE ─────────────────────────────────────
  Widget _buildPaso2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_outline,
                color: AppTheme.primary, size: 30),
          ),
          const SizedBox(height: 20),
          const Text('¿Cómo te llamas?',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Personaliza tu experiencia con tu nombre.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.badge_outlined,
                  color: AppTheme.primaryIcon, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _apellidoCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Apellido',
              prefixIcon: Icon(Icons.badge_outlined,
                  color: AppTheme.primaryIcon, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── PASO 3: DATOS FÍSICOS ──────────────────────────────
  Widget _buildPaso3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.monitor_weight_outlined,
                color: AppTheme.primary, size: 30),
          ),
          const SizedBox(height: 20),
          const Text('Tus datos físicos',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Los usamos para calcular tus métricas corporales.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Género
          const Text('Género',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: ['Hombre', 'Mujer'].map((g) {
              final sel = g == _genero;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _genero = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? AppTheme.primary : AppTheme.border),
                        boxShadow: sel
                            ? [BoxShadow(
                                color: AppTheme.primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            g == 'Hombre' ? Icons.male : Icons.female,
                            size: 18,
                            color: sel ? Colors.white : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(g,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Fecha de nacimiento
          const Text('Fecha de nacimiento',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _seleccionarFecha,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined,
                      color: AppTheme.primaryIcon, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fechaNacimiento != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(_fechaNacimiento!)
                          : 'Selecciona tu fecha de nacimiento',
                      style: TextStyle(
                          fontSize: 14,
                          color: _fechaNacimiento != null
                              ? AppTheme.textPrimary
                              : AppTheme.textHint),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_outlined,
                      color: AppTheme.primaryIcon, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Peso y talla
          const Text('Medidas corporales',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pesoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    hintText: 'Ej. 75',
                    prefixIcon: Icon(Icons.monitor_weight_outlined,
                        color: AppTheme.primaryIcon, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _tallaCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Talla (cm)',
                    hintText: 'Ej. 175',
                    prefixIcon: Icon(Icons.height,
                        color: AppTheme.primaryIcon, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PASO 4: OBJETIVO ───────────────────────────────────
  Widget _buildPaso4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.flag_outlined,
                color: AppTheme.success, size: 30),
          ),
          const SizedBox(height: 20),
          const Text('¿Cuál es tu objetivo?',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Selecciona tu meta principal. Podrás cambiarla después desde tu perfil.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          ...(_objetivos.map((o) {
            final sel = o['label'] == _objetivo;
            return GestureDetector(
              onTap: () => setState(() => _objetivo = o['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? AppTheme.primary : AppTheme.border,
                    width: sel ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(o['icon'] as IconData,
                          size: 22,
                          color: sel ? Colors.white : AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      o['label'] as String,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    if (sel)
                      const Icon(Icons.check_circle,
                          color: AppTheme.primary, size: 22),
                  ],
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  // ── PASO 5: RESUMEN CON MÉTRICAS ───────────────────────
  Widget _buildPaso5() {
    final nombre = _nombreCtrl.text.trim().isEmpty
        ? 'Atleta'
        : _nombreCtrl.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.successLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppTheme.success, size: 44),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Listo, $nombre!',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tu cuenta está lista. Revisa tus\nmétrocas iniciales antes de comenzar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Resumen de datos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryBorder),
            ),
            child: Column(
              children: [
                _resumenFila('Correo', _emailCtrl.text, Icons.mail_outline),
                const Divider(height: 16, color: AppTheme.primaryBorder),
                _resumenFila('Objetivo', _objetivo, Icons.flag_outlined),
                if (_pesoCtrl.text.isNotEmpty) ...[
                  const Divider(height: 16, color: AppTheme.primaryBorder),
                  _resumenFila('Peso', '${_pesoCtrl.text} kg',
                      Icons.monitor_weight_outlined),
                ],
                if (_tallaCtrl.text.isNotEmpty) ...[
                  const Divider(height: 16, color: AppTheme.primaryBorder),
                  _resumenFila(
                      'Talla', '${_tallaCtrl.text} cm', Icons.height),
                ],
                if (_edad != null) ...[
                  const Divider(height: 16, color: AppTheme.primaryBorder),
                  _resumenFila(
                      'Edad', '$_edad años', Icons.cake_outlined),
                ],
              ],
            ),
          ),

          // Métricas calculadas
          if (_imc != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0x18000000), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Métricas calculadas',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _metricaChip('IMC',
                          '${_imc!.toStringAsFixed(1)}', _categoriaImc, _colorImc),
                      const SizedBox(width: 10),
                      if (_pctGrasa != null)
                        _metricaChip('% Grasa',
                            '${_pctGrasa!.toStringAsFixed(1)}%', _genero,
                            const Color(0xFF0EA5E9)),
                      const SizedBox(width: 10),
                      if (_pesoIdeal != null)
                        _metricaChip('Peso ideal',
                            '${_pesoIdeal!.toStringAsFixed(1)} kg', 'IBW',
                            const Color(0xFF7C3AED)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '* Estimaciones basadas en fórmulas estándar.',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textHint,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _resumenFila(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _metricaChip(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(sub,
                style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── NAVEGACIÓN ─────────────────────────────────────────
  Widget _buildNavegacion() {
    final esUltimo = _paginaActual == 4;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Row(
          children: [
            if (_paginaActual > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _anterior,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Atrás',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            if (_paginaActual > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_puedeAvanzar && !_guardando) ? _siguiente : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.border,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        esUltimo ? '¡Crear cuenta!' : 'Continuar',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
