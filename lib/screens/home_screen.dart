// ============================================================
// home_screen.dart - GymTracker
// Pantalla de inicio con banner motivacional, tarjetas de
// métricas y últimas sesiones agrupadas por ejercicio.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../models/registro.dart';
import '../utils/app_theme.dart';
import '../widgets/ejercicio_image.dart';
import 'ejercicio_detalle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Registro> _recientes = [];
  Map<int, Ejercicio> _ejerciciosMap = {};
  int _totalEjercicios = 0;
  int _totalSesiones = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final recientes =
        await DatabaseHelper.instance.getRegistrosRecientes(limit: 30);
    final ejercicios = await DatabaseHelper.instance.getEjercicios();
    final map = {for (var e in ejercicios) e.id!: e};
    final totalEj = await DatabaseHelper.instance.getTotalEjercicios();
    final totalSe = await DatabaseHelper.instance.getTotalSesiones();

    setState(() {
      _recientes = recientes;
      _ejerciciosMap = map;
      _totalEjercicios = totalEj;
      _totalSesiones = totalSe;
      _loading = false;
    });
  }

  /// Agrupa registros recientes por ejercicioId,
  /// tomando el último registro de cada ejercicio.
  List<MapEntry<Ejercicio, Registro>> get _sesionesAgrupadas {
    final Map<int, Registro> ultimoPorEjercicio = {};
    for (final r in _recientes) {
      if (!ultimoPorEjercicio.containsKey(r.ejercicioId)) {
        ultimoPorEjercicio[r.ejercicioId] = r;
      }
    }
    return ultimoPorEjercicio.entries
        .where((e) => _ejerciciosMap.containsKey(e.key))
        .map((e) => MapEntry(_ejerciciosMap[e.key]!, e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildBanner(),
                        _buildMetricas(),
                        _buildUltimasSesiones(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center,
                size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
          const Text('GymTracker',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppTheme.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.person_outline,
              color: AppTheme.primary, size: 20),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    final hora = DateTime.now().hour;
    final saludo = hora < 12
        ? '¡Buenos días!'
        : hora < 18
            ? '¡Buenas tardes!'
            : '¡Buenas noches!';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(saludo,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 4),
                const Text('Sigue progresando 💪',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  DateFormat("EEEE, d 'de' MMMM", 'es')
                      .format(DateTime.now()),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _metricCard('Ejercicios', '$_totalEjercicios',
              Icons.fitness_center, AppTheme.primary, AppTheme.primaryLight),
          const SizedBox(width: 10),
          _metricCard('Sesiones', '$_totalSesiones',
              Icons.bar_chart_rounded, AppTheme.success, AppTheme.successLight),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon,
      Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x18000000), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUltimasSesiones() {
    final agrupadas = _sesionesAgrupadas;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Últimas sesiones',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              if (agrupadas.isNotEmpty)
                Text('${agrupadas.length} ejercicios',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          if (agrupadas.isEmpty)
            _buildEstadoVacio()
          else
            ...agrupadas.map((entry) =>
                _buildSesionItem(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18000000), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.fitness_center,
                color: AppTheme.primary, size: 30),
          ),
          const SizedBox(height: 14),
          const Text('Aún no hay registros',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Ve a Ejercicios y registra\ntu primera sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSesionItem(Registro r, Ejercicio ej) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EjercicioDetalleScreen(ejercicio: ej)));
        _cargar();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x18000000), width: 0.5),
        ),
        child: Row(
          children: [
            EjercicioImage(ejercicio: ej, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ej.nombre,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chipInfo(
                          '${r.peso.toStringAsFixed(r.peso % 1 == 0 ? 0 : 1)} kg',
                          Icons.fitness_center),
                      const SizedBox(width: 6),
                      _chipInfo('${r.series}×${r.reps}', Icons.repeat),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('dd/MM').format(r.fecha),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.grupoBgColor(ej.grupo),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(ej.grupo,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.grupoColor(ej.grupo),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.primary),
          const SizedBox(width: 3),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
