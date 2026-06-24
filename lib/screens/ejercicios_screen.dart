// ============================================================
// ejercicios_screen.dart - GymTracker
// Pantalla del catálogo de ejercicios mejorada visualmente.
// Filtros con chips estilizados, tarjetas con sombra suave
// y mejor jerarquía de información por ejercicio.
// ============================================================

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../utils/app_theme.dart';
import '../widgets/ejercicio_image.dart';
import 'ejercicio_detalle_screen.dart';
import 'ejercicio_form_screen.dart';

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

  Future<void> _cargar() async {
    final lista = await DatabaseHelper.instance.getEjercicios();
    setState(() => _ejercicios = lista);
  }

  List<Ejercicio> get _filtrados => _filtro == 'Todos'
      ? _ejercicios
      : _ejercicios.where((e) => e.grupo == _filtro).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Ejercicios',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EjercicioFormScreen()));
                _cargar();
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Nuevo',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          _buildContador(),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  // ── FILTROS ───────────────────────────────────────────────
  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: _grupos.map((g) {
          final sel = g == _filtro;
          final color = g == 'Push'
              ? AppTheme.primary
              : g == 'Pull'
                  ? AppTheme.success
                  : g == 'Pierna'
                      ? const Color(0xFF854F0B)
                      : AppTheme.textSecondary;
          final bgColor = g == 'Push'
              ? AppTheme.primaryLight
              : g == 'Pull'
                  ? AppTheme.successLight
                  : g == 'Pierna'
                      ? const Color(0xFFFAEEDA)
                      : const Color(0xFFF1EFE8);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filtro = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? color : AppTheme.border,
                      width: sel ? 0 : 0.5,
                    ),
                  ),
                  child: Text(
                    g,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── CONTADOR ──────────────────────────────────────────────
  Widget _buildContador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text(
            '${_filtrados.length} ejercicio${_filtrados.length != 1 ? 's' : ''}',
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500),
          ),
          if (_filtro != 'Todos') ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.grupoBgColor(_filtro),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _filtro,
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.grupoColor(_filtro),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── LISTA ─────────────────────────────────────────────────
  Widget _buildLista() {
    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center,
                  color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('No hay ejercicios',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Crea uno con el botón Nuevo',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filtrados.length,
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      itemBuilder: (context, i) {
        final e = _filtrados[i];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        EjercicioDetalleScreen(ejercicio: e)));
            _cargar();
          },
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0x18000000), width: 0.5),
            ),
            child: Row(
              children: [
                EjercicioImage(ejercicio: e, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 5),
                      Container(
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
