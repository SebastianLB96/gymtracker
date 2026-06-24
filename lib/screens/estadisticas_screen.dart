// ============================================================
// estadisticas_screen.dart - GymTracker
// Pantalla de estadísticas con resumen general (kg totales,
// racha de días, ejercicio más frecuente), distribución por
// grupo muscular, gráfica de progreso y calendario de sesiones
// para consultar registros por fecha.
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../models/registro.dart';
import '../utils/app_theme.dart';
import '../widgets/ejercicio_image.dart';
import 'ejercicio_detalle_screen.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  bool _loading = true;
  double _totalKg = 0;
  int _racha = 0;
  Map<String, dynamic>? _masFrec;
  Map<String, int> _porGrupo = {};
  String _grupoSeleccionado = 'Push';
  List<Map<String, dynamic>> _progreso = [];
  DateTime _fechaSeleccionada = DateTime.now();
  List<Registro> _registrosFecha = [];
  Map<int, Ejercicio> _ejerciciosMap = {};
  List<DateTime> _fechasConRegistros = [];
  int _mesActual = DateTime.now().month;
  int _anioActual = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final totalKg = await DatabaseHelper.instance.getTotalKgLevantados();
    final racha = await DatabaseHelper.instance.getRachaDias();
    final masFrec = await DatabaseHelper.instance.getEjercicioMasFrecuente();
    final porGrupo = await DatabaseHelper.instance.getSesionesPorGrupo();
    final fechas = await DatabaseHelper.instance.getFechasConRegistros();
    final ejercicios = await DatabaseHelper.instance.getEjercicios();
    final map = {for (var e in ejercicios) e.id!: e};
    await _cargarProgreso();
    await _cargarRegistrosFecha(_fechaSeleccionada);
    setState(() {
      _totalKg = totalKg;
      _racha = racha;
      _masFrec = masFrec;
      _porGrupo = porGrupo;
      _fechasConRegistros = fechas;
      _ejerciciosMap = map;
      _loading = false;
    });
  }

  Future<void> _cargarProgreso() async {
    final prog =
        await DatabaseHelper.instance.getProgresoGrupo(_grupoSeleccionado);
    setState(() => _progreso = prog);
  }

  Future<void> _cargarRegistrosFecha(DateTime fecha) async {
    final regs = await DatabaseHelper.instance.getRegistrosPorFecha(fecha);
    setState(() {
      _fechaSeleccionada = fecha;
      _registrosFecha = regs;
    });
  }

  bool _tieneSesion(DateTime fecha) {
    return _fechasConRegistros.any((f) =>
        f.year == fecha.year &&
        f.month == fecha.month &&
        f.day == fecha.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Estadísticas',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _buildResumen(),
                  _buildDistribucion(),
                  _buildGraficaProgreso(),
                  _buildCalendario(),
                  _buildRegistrosFecha(),
                ],
              ),
            ),
    );
  }

  // ── RESUMEN GENERAL ──────────────────────────────────────
  Widget _buildResumen() {
    String kgStr = _totalKg >= 1000
        ? '${(_totalKg / 1000).toStringAsFixed(1)}t'
        : '${_totalKg.toStringAsFixed(0)} kg';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen general',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _resumenCard(
                  'Total levantado', kgStr,
                  Icons.fitness_center, AppTheme.primary, AppTheme.primaryLight),
              const SizedBox(width: 10),
              _resumenCard(
                  'Racha', '$_racha días',
                  Icons.local_fire_department_outlined,
                  const Color(0xFFB45309), const Color(0xFFFEF3C7)),
            ],
          ),
          const SizedBox(height: 10),
          if (_masFrec != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0x18000000), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_outline,
                        color: AppTheme.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ejercicio más frecuente',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                        Text(
                          _masFrec!['nombre'] as String,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_masFrec!['total']} sesiones',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resumenCard(String label, String value, IconData icon,
      Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x18000000), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DISTRIBUCIÓN POR GRUPO ───────────────────────────────
  Widget _buildDistribucion() {
    if (_porGrupo.isEmpty) return const SizedBox.shrink();
    final total =
        _porGrupo.values.fold<int>(0, (a, b) => a + b);

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
          const Text('Sesiones por grupo muscular',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          ...['Push', 'Pull', 'Pierna'].map((g) {
            final val = _porGrupo[g] ?? 0;
            final pct = total > 0 ? val / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.grupoColor(g),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(g,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                      Text('$val sesiones',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      backgroundColor: AppTheme.grupoBgColor(g),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.grupoColor(g)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── GRÁFICA DE PROGRESO ──────────────────────────────────
  Widget _buildGraficaProgreso() {
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
          const Text('Progreso por grupo muscular',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),

          // Selector de grupo
          Row(
            children: ['Push', 'Pull', 'Pierna'].map((g) {
              final sel = g == _grupoSeleccionado;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _grupoSeleccionado = g);
                    await _cargarProgreso();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.grupoColor(g)
                          : AppTheme.grupoBgColor(g),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(g,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? Colors.white
                                : AppTheme.grupoColor(g))),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          if (_progreso.length < 2)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart,
                      color: AppTheme.textHint, size: 32),
                  const SizedBox(height: 8),
                  const Text('Necesitas al menos 2 sesiones',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            )
          else
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
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _progreso
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(),
                            (e.value['promedio'] as num).toDouble()))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.grupoColor(_grupoSeleccionado),
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.grupoBgColor(_grupoSeleccionado)
                          .withOpacity(0.5),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.grupoColor(_grupoSeleccionado),
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

  // ── CALENDARIO ───────────────────────────────────────────
  Widget _buildCalendario() {
    final primerDia = DateTime(_anioActual, _mesActual, 1);
    final diasEnMes = DateTime(_anioActual, _mesActual + 1, 0).day;
    final offsetInicio = primerDia.weekday % 7;

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
          // Header del calendario
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Registro por fecha',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: () => setState(() {
                      if (_mesActual == 1) {
                        _mesActual = 12;
                        _anioActual--;
                      } else {
                        _mesActual--;
                      }
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM yyyy', 'es')
                        .format(DateTime(_anioActual, _mesActual)),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: () => setState(() {
                      if (_mesActual == 12) {
                        _mesActual = 1;
                        _anioActual++;
                      } else {
                        _mesActual++;
                      }
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Días de la semana
          Row(
            children: ['D', 'L', 'M', 'X', 'J', 'V', 'S'].map((d) {
              return Expanded(
                child: Text(d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),

          // Grilla de días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: offsetInicio + diasEnMes,
            itemBuilder: (context, index) {
              if (index < offsetInicio) return const SizedBox.shrink();
              final dia = index - offsetInicio + 1;
              final fecha = DateTime(_anioActual, _mesActual, dia);
              final tieneSesion = _tieneSesion(fecha);
              final esHoy = fecha.year == DateTime.now().year &&
                  fecha.month == DateTime.now().month &&
                  fecha.day == DateTime.now().day;
              final esSel = fecha.year == _fechaSeleccionada.year &&
                  fecha.month == _fechaSeleccionada.month &&
                  fecha.day == _fechaSeleccionada.day;

              return GestureDetector(
                onTap: () => _cargarRegistrosFecha(fecha),
                child: Container(
                  decoration: BoxDecoration(
                    color: esSel
                        ? AppTheme.primary
                        : tieneSesion
                            ? AppTheme.primaryLight
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: esHoy && !esSel
                        ? Border.all(color: AppTheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dia',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: tieneSesion || esHoy
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: esSel
                              ? Colors.white
                              : tieneSesion
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                        ),
                      ),
                      if (tieneSesion && !esSel)
                        Positioned(
                          bottom: 3,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── REGISTROS DE LA FECHA SELECCIONADA ──────────────────
  Widget _buildRegistrosFecha() {
    final fechaStr = DateFormat("EEEE d 'de' MMMM", 'es')
        .format(_fechaSeleccionada);

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fechaStr[0].toUpperCase() + fechaStr.substring(1),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x18000000)),
          if (_registrosFecha.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: const [
                  Icon(Icons.event_busy_outlined,
                      color: AppTheme.textHint, size: 32),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sin sesiones este día',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_registrosFecha.map((r) {
              final ej = _ejerciciosMap[r.ejercicioId];
              if (ej == null) return const SizedBox.shrink();
              return Column(
                children: [
                  ListTile(
                    leading: EjercicioImage(ejercicio: ej, size: 40),
                    title: Text(ej.nombre,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary)),
                    subtitle: Text(
                      '${r.peso.toStringAsFixed(r.peso % 1 == 0 ? 0 : 1)} kg  •  ${r.series}×${r.reps}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: Text(
                      DateFormat('HH:mm').format(r.fecha),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EjercicioDetalleScreen(ejercicio: ej))),
                  ),
                  const Divider(height: 1, color: Color(0x18000000)),
                ],
              );
            })),
        ],
      ),
    );
  }
}
