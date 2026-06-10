// ============================================================
// home_screen.dart - GymTracker
// Pantalla de inicio que muestra el resumen del entrenamiento.
// Presenta las estadísticas generales del usuario (total de
// ejercicios registrados y sesiones completadas) y la lista
// de las últimas sesiones de entrenamiento para que el usuario
// pueda ver rápidamente su actividad reciente en el gimnasio
// y acceder directamente al detalle de cada ejercicio.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../models/registro.dart';
import '../utils/app_theme.dart';
import '../widgets/ejercicio_image.dart';
import 'ejercicio_detalle_screen.dart';

// Pantalla de inicio de GymTracker
// Es StatefulWidget porque carga datos de SQLite al abrirse
// y necesita actualizarse cuando el usuario registra sesiones
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

  // Carga todos los datos necesarios para la pantalla de inicio
  // desde la base de datos SQLite del celular:
  // - Últimas 10 sesiones de entrenamiento del usuario
  Future<void> _cargar() async {
    setState(() => _loading = true);
    final recientes =
        await DatabaseHelper.instance.getRegistrosRecientes(limit: 10);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('GymTracker'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                color: AppTheme.primary, size: 20),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _buildResumen(),
                  _buildUltimasSesiones(),
                ],
              ),
            ),
    );
  }

  Widget _buildResumen() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, sigue progresando 💪',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now()),
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricCard(
                  'Ejercicios', '$_totalEjercicios', Icons.fitness_center),
              const SizedBox(width: 10),
              _metricCard('Sesiones', '$_totalSesiones', Icons.history),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x22000000), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas sesiones',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          if (_recientes.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0x22000000), width: 0.5),
              ),
              child: const Center(
                child: Text(
                  'Aún no hay registros.\nVe a Ejercicios y empieza a entrenar.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...(_recientes.map((r) {
              final ej = _ejerciciosMap[r.ejercicioId];
              if (ej == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EjercicioDetalleScreen(ejercicio: ej)));
                  _cargar();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0x22000000), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      EjercicioImage(ejercicio: ej, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ej.nombre,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              '${r.peso.toStringAsFixed(r.peso % 1 == 0 ? 0 : 1)} kg  •  ${r.series}×${r.reps} reps',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM').format(r.fecha),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            })),
        ],
      ),
    );
  }
}
