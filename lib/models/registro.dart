// ============================================================
// registro.dart - GymTracker
// Es el modelo que representa una sesión de entrenamiento registrada.
// Cada vez que el usuario anota su peso, series y repeticiones
// en un ejercicio se crea un objeto Registro que se guarda
// en la base de datos SQLite del celular para llevar el
// historial de cargas progresivas del gimnasio.
// ============================================================

class Registro {
  final int? id;
  final int ejercicioId;
  final double peso;
  final int series;
  final int reps;
  final DateTime fecha;
  final String? nota;

  Registro({
    this.id,
    required this.ejercicioId,
    required this.peso,
    required this.series,
    required this.reps,
    required this.fecha,
    this.nota,
  });

  double get volumen => peso * series * reps;

  Map<String, dynamic> toMap() => {
        'id': id,
        'ejercicioId': ejercicioId,
        'peso': peso,
        'series': series,
        'reps': reps,
        'fecha': fecha.toIso8601String(),
        'nota': nota,
      };

  factory Registro.fromMap(Map<String, dynamic> m) => Registro(
        id: m['id'],
        ejercicioId: m['ejercicioId'],
        peso: (m['peso'] as num).toDouble(),
        series: m['series'],
        reps: m['reps'],
        fecha: DateTime.parse(m['fecha']),
        nota: m['nota'],
      );
}
