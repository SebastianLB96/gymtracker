// ============================================================
// ejercicio_detalle_screen.dart - GymTracker
// Pantalla de detalle mejorada visualmente con header
// con gradiente, tarjetas de stats mejoradas, formulario
// con mejor UX y gráfica e historial más pulidos.
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../models/registro.dart';
import '../utils/app_theme.dart';
import '../widgets/ejercicio_image.dart';
import 'ejercicio_form_screen.dart';

class EjercicioDetalleScreen extends StatefulWidget {
  final Ejercicio ejercicio;

  const EjercicioDetalleScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioDetalleScreen> createState() =>
      _EjercicioDetalleScreenState();
}

class _EjercicioDetalleScreenState extends State<EjercicioDetalleScreen> {
  late Ejercicio _ejercicio;
  List<Registro> _registros = [];
  final _pesoCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _ejercicio = widget.ejercicio;
    _cargar();
  }

  Future<void> _cargar() async {
    final registros = await DatabaseHelper.instance
        .getRegistrosByEjercicio(_ejercicio.id!);
    final ej = await DatabaseHelper.instance.getEjercicio(_ejercicio.id!);
    setState(() {
      _registros = registros;
      if (ej != null) _ejercicio = ej;
    });

    if (_registros.isNotEmpty && _pesoCtrl.text.isEmpty) {
      final ultimo = _registros.last;
      _pesoCtrl.text =
          ultimo.peso.toStringAsFixed(ultimo.peso % 1 == 0 ? 0 : 1);
      _seriesCtrl.text = ultimo.series.toString();
      _repsCtrl.text = ultimo.reps.toString();
    }
  }

  Future<void> _guardar() async {
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
    final series = int.tryParse(_seriesCtrl.text);
    final reps = int.tryParse(_repsCtrl.text);

    if (peso == null || series == null || reps == null || peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Completa peso, series y repeticiones')),
      );
      return;
    }

    setState(() => _guardando = true);

    final record =
        await DatabaseHelper.instance.getRecordPeso(_ejercicio.id!);
    final esRecord = record == null || peso > record;

    await DatabaseHelper.instance.insertRegistro(Registro(
      ejercicioId: _ejercicio.id!,
      peso: peso,
      series: series,
      reps: reps,
      fecha: DateTime.now(),
      nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
    ));

    _notaCtrl.clear();
    await _cargar();
    setState(() => _guardando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            esRecord ? '🏆 ¡Nuevo récord! $peso kg' : 'Registro guardado'),
        backgroundColor: esRecord ? AppTheme.success : AppTheme.primary,
      ));
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _seriesCtrl.dispose();
    _repsCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_registros.isNotEmpty) _buildStats(),
                _buildFormRegistro(),
                if (_registros.length >= 2) _buildGrafica(),
                _buildHistorial(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SLIVER APP BAR CON HEADER VISUAL ─────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      toolbarHeight: 48,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        EjercicioFormScreen(ejercicio: _ejercicio)));
            _cargar();
          },
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: EjercicioImage(
                      ejercicio: _ejercicio,
                      size: 80,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _ejercicio.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _ejercicio.grupo,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_registros.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${_registros.length} sesiones registradas',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── ESTADÍSTICAS ──────────────────────────────────────────
  Widget _buildStats() {
    final maxPeso =
        _registros.map((r) => r.peso).reduce((a, b) => a > b ? a : b);
    final ultimo = _registros.last;
    final ganancia = ultimo.peso - _registros.first.peso;

    String fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _statCard('Récord', '${fmt(maxPeso)} kg',
              Icons.emoji_events_outlined, const Color(0xFFD4A017),
              const Color(0xFFFFF8E7)),
          const SizedBox(width: 8),
          _statCard('Último', '${fmt(ultimo.peso)} kg',
              Icons.fitness_center_outlined, AppTheme.primary,
              AppTheme.primaryLight),
          const SizedBox(width: 8),
          _statCard(
            'Progreso',
            '${ganancia >= 0 ? '+' : ''}${ganancia.toStringAsFixed(1)} kg',
            ganancia > 0 ? Icons.trending_up : Icons.trending_flat,
            ganancia > 0 ? AppTheme.success : AppTheme.textSecondary,
            ganancia > 0
                ? AppTheme.successLight
                : const Color(0xFFF1EFE8),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon,
      Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x18000000), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── FORMULARIO DE REGISTRO ────────────────────────────────
  Widget _buildFormRegistro() {
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
          // Header del formulario
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Registrar nueva sesión',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _campoNumerico(
                            _pesoCtrl, 'Peso (kg)', '80', Icons.monitor_weight_outlined)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _campoNumerico(
                            _seriesCtrl, 'Series', '4', Icons.layers_outlined)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _campoNumerico(
                            _repsCtrl, 'Reps', '8', Icons.repeat)),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notaCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nota opcional (ej: buena técnica)',
                    prefixIcon: Icon(Icons.note_outlined,
                        color: AppTheme.primaryIcon, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined,
                            size: 18, color: Colors.white),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar registro',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoNumerico(TextEditingController ctrl, String label,
      String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 16, color: AppTheme.primaryIcon),
      ),
    );
  }

  // ── GRÁFICA ───────────────────────────────────────────────
  Widget _buildGrafica() {
    final spots = _registros
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.peso))
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18000000), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart,
                    size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              const Text(
                'Evolución del peso (kg)',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0x11000000), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primary,
                  barWidth: 2.5,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryLight.withOpacity(0.5),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  // ── HISTORIAL ─────────────────────────────────────────────
  Widget _buildHistorial() {
    if (_registros.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x18000000), width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.history,
                  color: AppTheme.primary, size: 26),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin registros aún',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              '¡Completa tu primera sesión!',
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final invertidos = _registros.reversed.toList();

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
          // Header historial
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history,
                      size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Historial de sesiones',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                const Spacer(),
                Text(
                  '${_registros.length} total',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x18000000)),

          ...invertidos.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final prev =
                i < invertidos.length - 1 ? invertidos[i + 1] : null;
            final subio = prev != null && r.peso > prev.peso;
            final bajo = prev != null && r.peso < prev.peso;
            final vol = (r.peso * r.series * r.reps).toStringAsFixed(0);

            final indicatorColor = subio
                ? AppTheme.success
                : bajo
                    ? Colors.red
                    : AppTheme.textSecondary;
            final indicatorIcon = subio
                ? Icons.arrow_upward
                : bajo
                    ? Icons.arrow_downward
                    : Icons.remove;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Indicador
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: indicatorColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(indicatorIcon,
                            size: 14, color: indicatorColor),
                      ),
                      const SizedBox(width: 12),

                      // Datos principales
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${r.peso.toStringAsFixed(r.peso % 1 == 0 ? 0 : 1)} kg',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${r.series}×${r.reps}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vol: $vol kg  •  ${DateFormat('dd MMM yyyy', 'es').format(r.fecha)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                            if (r.nota != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  r.nota!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textSecondary),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Botón eliminar
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppTheme.textSecondary),
                        onPressed: () async {
                          await DatabaseHelper.instance
                              .deleteRegistro(r.id!);
                          _cargar();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                if (i < invertidos.length - 1)
                  const Divider(height: 1, color: Color(0x18000000)),
              ],
            );
          }),
        ],
      ),
    );
  }
}
