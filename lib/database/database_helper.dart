// ============================================================
// database_helper.dart - GymTracker
// Gestiona toda la comunicación con la base de datos SQLite
// del celular. Crea y mantiene las tablas de ejercicios y
// registros de entrenamiento. Proporciona todos los métodos
// para guardar, consultar, actualizar y eliminar los datos
// del historial de cargas progresivas del usuario.
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ejercicio.dart';
import '../models/registro.dart';

// Clase que maneja la base de datos local SQLite de GymTracker
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  // Crea el archivo gymtracker.db en el directorio de datos
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gymtracker.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── TABLA EJERCICIOS ──────────────────────────────────────
    // Almacena el catálogo de ejercicios del usuario
    await db.execute('''
      CREATE TABLE ejercicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        grupo TEXT NOT NULL,
        imagenAsset TEXT,
        imagenPath TEXT
      )
    ''');
    // ── TABLA REGISTROS ───────────────────────────────────────
    // Almacena cada sesión de entrenamiento registrada
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

    await _insertEjerciciosPredefinidos(db);
  }

  // Inserta los 18 ejercicios predefinidos de la rutina
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

  // ── EJERCICIOS ──────────────────────────────────────
  Future<List<Ejercicio>> getEjercicios() async {
    final d = await db;
    final maps = await d.query('ejercicios', orderBy: 'grupo, nombre');
    return maps.map(Ejercicio.fromMap).toList();
  }

  Future<Ejercicio?> getEjercicio(int id) async {
    final d = await db;
    final maps =
        await d.query('ejercicios', where: 'id = ?', whereArgs: [id]);
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
    await d.update('ejercicios', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteEjercicio(int id) async {
    final d = await db;
    await d.delete('registros', where: 'ejercicioId = ?', whereArgs: [id]);
    await d.delete('ejercicios', where: 'id = ?', whereArgs: [id]);
  }

  // ── REGISTROS ────────────────────────────────────────
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
    final maps = await d.query('registros',
        orderBy: 'fecha DESC', limit: limit);
    return maps.map(Registro.fromMap).toList();
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

  Future<int> getTotalEjercicios() async {
    final d = await db;
    final result =
        await d.rawQuery('SELECT COUNT(*) as count FROM ejercicios');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalSesiones() async {
    final d = await db;
    final result =
        await d.rawQuery('SELECT COUNT(*) as count FROM registros');
    return (result.first['count'] as int?) ?? 0;
  }
}
