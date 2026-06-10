// ============================================================
// ejercicios_screen.dart - GymTracker
// Pantalla que muestra el catálogo completo de ejercicios
// del usuario organizados por grupo muscular. Permite filtrar
// por Push (pecho/hombros/tríceps), Pull (espalda/bíceps) o
// Pierna (cuádriceps/femoral/gemelos). El usuario puede crear
// nuevos ejercicios con foto de la máquina de su gimnasio
// o acceder al detalle de cada ejercicio para registrar
// su sesión de entrenamiento y ver su progreso de cargas.
// ============================================================

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../utils/app_theme.dart';
import '../widgets/ejercicio_image.dart';
import 'ejercicio_detalle_screen.dart';
import 'ejercicio_form_screen.dart';

// Pantalla del catálogo de ejercicios de GymTracker
// Es StatefulWidget porque maneja el filtro activo
// y recarga la lista al crear o editar ejercicios
class EjerciciosScreen extends StatefulWidget {
  const EjerciciosScreen({super.key});

  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen> {
  List<Ejercicio> _ejercicios = [];
  String _filtro = 'Todos';
  final _grupos = ['Todos', 'Push', 'Pull', 'Pierna'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Obtiene todos los ejercicios de SQLite y actualiza la lista
  // Se llama al iniciar y al regresar de crear o editar ejercicios
  Future<void> _cargar() async {
    final lista = await DatabaseHelper.instance.getEjercicios();
    setState(() => _ejercicios = lista);
  }

  // Propiedad que filtra los ejercicios según el grupo seleccionado
  List<Ejercicio> get _filtrados => _filtro == 'Todos'
      ? _ejercicios
      : _ejercicios.where((e) => e.grupo == _filtro).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EjercicioFormScreen()));
              _cargar();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _grupos.map((g) {
            final sel = g == _filtro;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filtro = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppTheme.primary : AppTheme.border,
                      width: sel ? 0 : 0.5,
                    ),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: sel ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_filtrados.isEmpty) {
      return const Center(
        child: Text('No hay ejercicios',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: _filtrados.length,
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemBuilder: (context, i) {
        final e = _filtrados[i];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0x22000000), width: 0.5),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: EjercicioImage(ejercicio: e, size: 48),
            title: Text(
              e.nombre,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppTheme.textPrimary),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.grupoBgColor(e.grupo),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.grupo,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.grupoColor(e.grupo),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary),
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          EjercicioDetalleScreen(ejercicio: e)));
              _cargar();
            },
          ),
        );
      },
    );
  }
}
