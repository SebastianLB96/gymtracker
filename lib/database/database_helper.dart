// ============================================================
// database_helper.dart - GymTracker
// Gestiona toda la comunicación con la base de datos SQLite.
// Incluye tablas de ejercicios, registros y perfil de usuario.
// Versión 2: agrega tabla perfil y métodos de estadísticas.
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ejercicio.dart';
import '../models/registro.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gymtracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ejercicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        grupo TEXT NOT NULL,
        imagenAsset TEXT,
        imagenPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE registros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ejercicioId INTEGER NOT NULL,
        peso REAL NOT NULL,
        series INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        nota TEXT,
        FOREIGN KEY (ejercicioId) REFERENCES ejercicios(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE perfil (
        id INTEGER PRIMARY KEY,
        nombre TEXT,
        apellido TEXT,
        email TEXT,
        genero TEXT,
        fechaNacimiento TEXT,
        pesoKg REAL,
        tallaCm REAL,
        objetivo TEXT,
        fotoPerfil TEXT
      )
    ''');

    await _insertEjerciciosPredefinidos(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS perfil (
          id INTEGER PRIMARY KEY,
          nombre TEXT,
          apellido TEXT,
          email TEXT,
          genero TEXT,
          fechaNacimiento TEXT,
          pesoKg REAL,
          tallaCm REAL,
          objetivo TEXT,
          fotoPerfil TEXT
        )
      ''');
    }
  }

  Future<void> _insertEjerciciosPredefinidos(Database db) async {
    final ejercicios = [
      {'nombre': 'Press de Pecho en Máquina', 'grupo': 'Push'},
      {'nombre': 'Press Inclinado en Máquina', 'grupo': 'Push'},
      {'nombre': 'Aperturas en Máquina', 'grupo': 'Push'},
      {'nombre': 'Press Militar en Máquina', 'grupo': 'Push'},
      {'nombre': 'Elevaciones Laterales', 'grupo': 'Push'},
      {'nombre': 'Tríceps en Polea', 'grupo': 'Push'},
      {'nombre': 'Jalón al Pecho', 'grupo': 'Pull'},
      {'nombre': 'Remo Sentado en Máquina', 'grupo': 'Pull'},
      {'nombre': 'Remo con Barra', 'grupo': 'Pull'},
      {'nombre': 'Curl de Bíceps en Máquina', 'grupo': 'Pull'},
      {'nombre': 'Curl Martillo', 'grupo': 'Pull'},
      {'nombre': 'Face Pulls', 'grupo': 'Pull'},
      {'nombre': 'Sentadilla en Máquina', 'grupo': 'Pierna'},
      {'nombre': 'Prensa de Pierna', 'grupo': 'Pierna'},
      {'nombre': 'Extensión de Cuádriceps', 'grupo': 'Pierna'},
      {'nombre': 'Curl Femoral', 'grupo': 'Pierna'},
      {'nombre': 'Elevación de Talones', 'grupo': 'Pierna'},
      {'nombre': 'Peso Muerto Rumano', 'grupo': 'Pierna'},
    ];
    for (final e in ejercicios) {
      await db.insert('ejercicios', e);
    }
  }

  // ── EJERCICIOS ──────────────────────────────────────────────
  Future<List<Ejercicio>> getEjercicios() async {
    final d = await db;
    final maps = await d.query('ejercicios', orderBy: 'grupo, nombre');
    return maps.map(Ejercicio.fromMap).toList();
  }

  Future<Ejercicio?> getEjercicio(int id) async {
    final d = await db;
    final maps = await d.query('ejercicios', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Ejercicio.fromMap(maps.first);
  }

  Future<int> insertEjercicio(Ejercicio e) async {
    final d = await db;
    final map = e.toMap()..remove('id');
    return await d.insert('ejercicios', map);
  }

  Future<void> updateEjercicio(Ejercicio e) async {
    final d = await db;
    await d.update('ejercicios', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteEjercicio(int id) async {
    final d = await db;
    await d.delete('registros', where: 'ejercicioId = ?', whereArgs: [id]);
    await d.delete('ejercicios', where: 'id = ?', whereArgs: [id]);
  }

  // ── REGISTROS ───────────────────────────────────────────────
  Future<int> insertRegistro(Registro r) async {
    final d = await db;
    final map = r.toMap()..remove('id');
    return await d.insert('registros', map);
  }

  Future<List<Registro>> getRegistrosByEjercicio(int ejercicioId) async {
    final d = await db;
    final maps = await d.query(
      'registros',
      where: 'ejercicioId = ?',
      whereArgs: [ejercicioId],
      orderBy: 'fecha ASC',
    );
    return maps.map(Registro.fromMap).toList();
  }

  Future<List<Registro>> getRegistrosRecientes({int limit = 20}) async {
    final d = await db;
    final maps = await d.query('registros', orderBy: 'fecha DESC', limit: limit);
    return maps.map(Registro.fromMap).toList();
  }

  /// Retorna registros del día indicado (fecha exacta yyyy-MM-dd)
  Future<List<Registro>> getRegistrosPorFecha(DateTime fecha) async {
    final d = await db;
    final fechaStr = fecha.toIso8601String().substring(0, 10);
    final maps = await d.query(
      'registros',
      where: "fecha LIKE ?",
      whereArgs: ['$fechaStr%'],
      orderBy: 'fecha DESC',
    );
    return maps.map(Registro.fromMap).toList();
  }

  /// Retorna fechas únicas que tienen registros (para marcar el calendario)
  Future<List<DateTime>> getFechasConRegistros() async {
    final d = await db;
    final result = await d.rawQuery(
      "SELECT DISTINCT substr(fecha, 1, 10) as dia FROM registros ORDER BY dia DESC",
    );
    return result
        .map((r) => DateTime.parse(r['dia'] as String))
        .toList();
  }

  Future<Registro?> getUltimoRegistro(int ejercicioId) async {
    final d = await db;
    final maps = await d.query(
      'registros',
      where: 'ejercicioId = ?',
      whereArgs: [ejercicioId],
      orderBy: 'fecha DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Registro.fromMap(maps.first);
  }

  Future<double?> getRecordPeso(int ejercicioId) async {
    final d = await db;
    final result = await d.rawQuery(
      'SELECT MAX(peso) as maxPeso FROM registros WHERE ejercicioId = ?',
      [ejercicioId],
    );
    return result.first['maxPeso'] as double?;
  }

  Future<void> deleteRegistro(int id) async {
    final d = await db;
    await d.delete('registros', where: 'id = ?', whereArgs: [id]);
  }

  // ── ESTADÍSTICAS ────────────────────────────────────────────
  Future<int> getTotalEjercicios() async {
    final d = await db;
    final result = await d.rawQuery('SELECT COUNT(*) as count FROM ejercicios');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalSesiones() async {
    final d = await db;
    final result = await d.rawQuery('SELECT COUNT(*) as count FROM registros');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Total de kg levantados (peso × series × reps de cada registro)
  Future<double> getTotalKgLevantados() async {
    final d = await db;
    final result = await d.rawQuery(
      'SELECT SUM(peso * series * reps) as total FROM registros',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Racha actual de días consecutivos con registros
  Future<int> getRachaDias() async {
    final fechas = await getFechasConRegistros();
    if (fechas.isEmpty) return 0;
    final hoy = DateTime.now();
    int racha = 0;
    DateTime cursor = DateTime(hoy.year, hoy.month, hoy.day);
    for (int i = 0; i < 365; i++) {
      final tiene = fechas.any((f) =>
          f.year == cursor.year &&
          f.month == cursor.month &&
          f.day == cursor.day);
      if (tiene) {
        racha++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return racha;
  }

  /// Ejercicio con más registros (más frecuente)
  Future<Map<String, dynamic>?> getEjercicioMasFrecuente() async {
    final d = await db;
    final result = await d.rawQuery('''
      SELECT e.nombre, e.grupo, COUNT(r.id) as total
      FROM registros r
      JOIN ejercicios e ON r.ejercicioId = e.id
      GROUP BY r.ejercicioId
      ORDER BY total DESC
      LIMIT 1
    ''');
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Registros agrupados por grupo muscular (para gráfica)
  Future<Map<String, int>> getSesionesPorGrupo() async {
    final d = await db;
    final result = await d.rawQuery('''
      SELECT e.grupo, COUNT(r.id) as total
      FROM registros r
      JOIN ejercicios e ON r.ejercicioId = e.id
      GROUP BY e.grupo
    ''');
    final map = <String, int>{};
    for (final row in result) {
      map[row['grupo'] as String] = (row['total'] as int?) ?? 0;
    }
    return map;
  }

  /// Progreso de peso por grupo muscular en el tiempo
  Future<List<Map<String, dynamic>>> getProgresoGrupo(String grupo) async {
    final d = await db;
    return await d.rawQuery('''
      SELECT r.fecha, AVG(r.peso) as promedio
      FROM registros r
      JOIN ejercicios e ON r.ejercicioId = e.id
      WHERE e.grupo = ?
      GROUP BY substr(r.fecha, 1, 10)
      ORDER BY r.fecha ASC
      LIMIT 30
    ''', [grupo]);
  }

  // ── PERFIL ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getPerfil() async {
    final d = await db;
    final maps = await d.query('perfil', where: 'id = 1');
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> savePerfil(Map<String, dynamic> data) async {
    final d = await db;
    final existing = await d.query('perfil', where: 'id = 1');
    if (existing.isEmpty) {
      await d.insert('perfil', {...data, 'id': 1});
    } else {
      await d.update('perfil', data, where: 'id = 1');
    }
  }
}
