// ============================================================
// ejercicio.dart - GymTracker
// Es el modelo que representa un ejercicio del gimnasio.
// Cada ejercicio tiene un nombre, pertenece a un grupo
// muscular (Push, Pull o Pierna) y puede tener una foto
// de la máquina tomada por el usuario en su gimnasio.
// ============================================================

class Ejercicio {
  final int? id;
  final String nombre;
  final String grupo;
  final String? imagenAsset;
  final String? imagenPath;

  Ejercicio({
    this.id,
    required this.nombre,
    required this.grupo,
    this.imagenAsset,
    this.imagenPath,
  });

  // Convierte el objeto Ejercicio a un Map para guardarlo en SQLite
  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'grupo': grupo,
        'imagenAsset': imagenAsset,
        'imagenPath': imagenPath,
      };

  factory Ejercicio.fromMap(Map<String, dynamic> m) => Ejercicio(
        id: m['id'],
        nombre: m['nombre'],
        grupo: m['grupo'],
        imagenAsset: m['imagenAsset'],
        imagenPath: m['imagenPath'],
      );

  Ejercicio copyWith({
    int? id,
    String? nombre,
    String? grupo,
    String? imagenAsset,
    String? imagenPath,
  }) =>
      Ejercicio(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        grupo: grupo ?? this.grupo,
        imagenAsset: imagenAsset ?? this.imagenAsset,
        imagenPath: imagenPath ?? this.imagenPath,
      );
}
