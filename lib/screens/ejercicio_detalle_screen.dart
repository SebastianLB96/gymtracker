// ============================================================
// ejercicio_detalle_screen.dart - GymTracker
// Pantalla más completa de la aplicación. Muestra toda la
// información de un ejercicio específico del gimnasio:
// - Header con imagen de la máquina y grupo muscular
// - Estadísticas: récord personal, último peso y progreso total
// - Formulario para registrar la sesión de entrenamiento actual
//   con peso, series, repeticiones y nota opcional
// - Gráfica de línea con la evolución del peso a lo largo
//   del tiempo para visualizar la sobrecarga progresiva
// - Historial completo de todas las sesiones registradas
//   con indicador visual de si el peso subió o se mantuvo
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

// Pantalla de detalle de un ejercicio en GymTracker
class EjercicioDetalleScreen extends StatefulWidget {
  final Ejercicio ejercicio;

  const EjercicioDetalleScreen({super.key, required this.ejercicio});

  @override
  State<EjercicioDetalleScreen> createState() =>
      _EjercicioDetalleScreenState();
}

class _EjercicioDetalleScreenState extends State<EjercicioDetalleScreen> {

  // Datos actualizados del ejercicio incluyendo foto
  // Se recarga después de editar para mostrar cambios
  late Ejercicio _ejercicio;
  List<Registro> _registros = [];
  final _pesoCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  bool _guardando = false;

  // Carga el historial del ejercicio al abrir la pantalla
  @override
  void initState() {
    super.initState();
    _ejercicio = widget.ejercicio;
    _cargar();
  }

  // Carga el historial completo de sesiones del ejercicio
  // desde SQLite y pre-llena los campos del formulario
  // con los datos de la última sesión como referencia
  // para que el usuario sepa desde dónde continuar su progreso
  Future<void> _cargar() async {
    final registros = await DatabaseHelper.instance
        .getRegistrosByEjercicio(_ejercicio.id!);

    // Recarga el ejercicio para mostrar foto actualizada
    // si el usuario la cambió desde la pantalla de edición
    final ej = await DatabaseHelper.instance.getEjercicio(_ejercicio.id!);
    setState(() {
      _registros = registros;
      if (ej != null) _ejercicio = ej;
    });

    if (_registros.isNotEmpty && _pesoCtrl.text.isEmpty) {
      final ultimo = _registros.last;
      _pesoCtrl.text = ultimo.peso
          .toStringAsFixed(ultimo.peso % 1 == 0 ? 0 : 1);
      _seriesCtrl.text = ultimo.series.toString();
      _repsCtrl.text = ultimo.reps.toString();
    }
  }

  // Guarda la nueva sesión de entrenamiento en SQLite
  // Verifica si el peso supera el récord personal anterior
  // y muestra notificación especial si es un nuevo récord
  Future<void> _guardar() async {
    final peso =
        double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
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

    // Guarda la nueva sesión en la base de datos SQLite
    await DatabaseHelper.instance.insertRegistro(Registro(
      ejercicioId: _ejercicio.id!,
      peso: peso,
      series: series,
      reps: reps,
      fecha: DateTime.now(),
      nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
    ));

    _notaCtrl.clear();

    // Recarga el historial para mostrar la nueva sesión
    await _cargar();
    setState(() => _guardando = false);

    if (mounted) {

      // Notificación especial verde si es nuevo récord personal
      // Motiva al usuario a seguir superando sus marcas
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            esRecord ? '🏆 ¡Nuevo récord! $peso kg' : 'Registro guardado'),
        backgroundColor:
            esRecord ? AppTheme.success : AppTheme.primary,
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
      appBar: AppBar(
        title: Text(_ejercicio.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EjercicioFormScreen(
                          ejercicio: _ejercicio)));
              _cargar();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildHeader(),
          if (_registros.isNotEmpty) _buildStats(),
          _buildFormRegistro(),
          if (_registros.length >= 2) _buildGrafica(),
          _buildHistorial(),
        ],
      ),
    );
  }

  // Construye el encabezado con la foto de la máquina,
  // nombre, grupo muscular y total de sesiones registradas
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          EjercicioImage(
              ejercicio: _ejercicio,
              size: 72,
              borderRadius: BorderRadius.circular(12)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ejercicio.nombre,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.grupoBgColor(_ejercicio.grupo),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _ejercicio.grupo,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.grupoColor(_ejercicio.grupo),
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (_registros.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${_registros.length} sesiones',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construye las tarjetas de estadísticas del ejercicio:
  // - Récord personal: el mayor peso levantado históricamente
  // - Último peso: referencia para la sesión actual
  // - Progreso total: diferencia entre primera y última sesió
  Widget _buildStats() {
    final maxPeso = _registros
        .map((r) => r.peso)
        .reduce((a, b) => a > b ? a : b);
    final ultimo = _registros.last;
    final ganancia = ultimo.peso - _registros.first.peso;

    String fmt(double v) =>
        v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _statCard('Récord', '${fmt(maxPeso)} kg',
              Icons.emoji_events_outlined),
          const SizedBox(width: 10),
          _statCard('Último', '${fmt(ultimo.peso)} kg',
              Icons.fitness_center_outlined),
          const SizedBox(width: 10),
          _statCard(
              'Progreso',
              '${ganancia >= 0 ? '+' : ''}${ganancia.toStringAsFixed(1)} kg',
              Icons.trending_up,
              color: ganancia > 0 ? AppTheme.success : AppTheme.textSecondary),
        ],
      ),
    );
  }

  // Construye una tarjeta individual de estadística
  /// con ícono, valor numérico y etiqueta descriptiva
  Widget _statCard(String label, String value, IconData icon,
      {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: const Color(0x22000000), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 16, color: color ?? AppTheme.primary),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color ?? AppTheme.textPrimary)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // Construye el formulario para registrar la sesión actual
  // Los campos se pre-llenan con los valores de la última
  // sesión para que el usuario sepa desde dónde progresar
  Widget _buildFormRegistro() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar nueva sesión',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _campoNumerico(
                      _pesoCtrl, 'Peso (kg)', '80')),
              const SizedBox(width: 10),
              Expanded(
                  child: _campoNumerico(
                      _seriesCtrl, 'Series', '4')),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _campoNumerico(_repsCtrl, 'Reps', '8')),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _notaCtrl,
            decoration: const InputDecoration(
              hintText: 'Nota (opcional)',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar registro'),
            ),
          ),
        ],
      ),
    );
  }

  // Construye un campo numérico del formulario de registro
  // Acepta tanto teclado numérico con decimales
  Widget _campoNumerico(
      TextEditingController ctrl, String label, String hint) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  // Construye la gráfica de línea con la evolución del peso
  // a lo largo del tiempo usando la librería fl_chart
  // Muestra visualmente la sobrecarga progresiva del usuario
  // Solo se muestra cuando hay al menos 2 registros
  Widget _buildGrafica() {
    final spots = _registros
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.peso))
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evolución del peso (kg)',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
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
                  dotData: const FlDotData(show: true),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  // Construye el historial completo de sesiones del ejercicio
  // ordenado de más reciente a más antiguo con:
  // - Flecha verde si el peso subió respecto a la sesión anterior
  // - Guión gris si el peso se mantuvo igual
  // - Volumen total calculado (peso × series × reps)
  // - Fecha en español y nota si existe
  // - Botón de papelera para eliminar el registro
  Widget _buildHistorial() {
    if (_registros.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Aún no hay registros.\n¡Completa tu primera sesión!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final invertidos = _registros.reversed.toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22000000), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Historial de sesiones',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
          ),
          ...invertidos.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final prev = i < invertidos.length - 1
                ? invertidos[i + 1]
                : null;
            final subio = prev != null && r.peso > prev.peso;
            final vol =
                (r.peso * r.series * r.reps).toStringAsFixed(0);

            return Column(
              children: [
                ListTile(
                  dense: true,
                  leading: Icon(
                    subio ? Icons.arrow_upward : Icons.remove,
                    size: 16,
                    color: subio
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                  ),
                  title: Row(
                    children: [
                      Text(
                        '${r.peso.toStringAsFixed(r.peso % 1 == 0 ? 0 : 1)} kg',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${r.series}×${r.reps}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vol: $vol kg  •  ${DateFormat('dd MMM yyyy', 'es').format(r.fecha)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (r.nota != null)
                        Text(r.nota!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondary)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () async {
                      await DatabaseHelper.instance
                          .deleteRegistro(r.id!);
                      _cargar();
                    },
                  ),
                ),
                if (i < invertidos.length - 1)
                  const Divider(height: 1, indent: 52),
              ],
            );
          }),
        ],
      ),
    );
  }
}
