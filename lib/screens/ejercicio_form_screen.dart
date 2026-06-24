// ============================================================
// ejercicio_form_screen.dart - GymTracker
// Formulario mejorado para crear o editar ejercicios.
// Header con gradiente, sección de foto más visual y
// selector de grupo muscular con colores por categoría.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../utils/app_theme.dart';

class EjercicioFormScreen extends StatefulWidget {
  final Ejercicio? ejercicio;

  const EjercicioFormScreen({super.key, this.ejercicio});

  @override
  State<EjercicioFormScreen> createState() => _EjercicioFormScreenState();
}

class _EjercicioFormScreenState extends State<EjercicioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  String _grupo = 'Push';
  String? _imagenPath;
  bool _guardando = false;
  final _grupos = ['Push', 'Pull', 'Pierna'];

  @override
  void initState() {
    super.initState();
    if (widget.ejercicio != null) {
      _nombreCtrl.text = widget.ejercicio!.nombre;
      _grupo = widget.ejercicio!.grupo;
      _imagenPath = widget.ejercicio!.imagenPath;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 800);
    if (picked != null) setState(() => _imagenPath = picked.path);
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2))),

              const Text(
                'Foto de la máquina',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),

              _opcionFoto(
                icon: Icons.camera_alt_outlined,
                label: 'Tomar foto a la máquina',
                sublabel: 'Abre la cámara del celular',
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.camera);
                },
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _opcionFoto(
                icon: Icons.photo_library_outlined,
                label: 'Elegir de la galería',
                sublabel: 'Selecciona una foto existente',
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.gallery);
                },
              ),

              if (_imagenPath != null) ...[
                const Divider(height: 1, indent: 20, endIndent: 20),
                _opcionFoto(
                  icon: Icons.delete_outline,
                  label: 'Eliminar foto',
                  sublabel: 'Volver al ícono predeterminado',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imagenPath = null);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcionFoto({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppTheme.primary;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? AppTheme.textPrimary)),
      subtitle: Text(sublabel,
          style:
              const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      onTap: onTap,
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final ejercicio = Ejercicio(
      id: widget.ejercicio?.id,
      nombre: _nombreCtrl.text.trim(),
      grupo: _grupo,
      imagenPath: _imagenPath,
    );

    if (widget.ejercicio == null) {
      await DatabaseHelper.instance.insertEjercicio(ejercicio);
    } else {
      await DatabaseHelper.instance.updateEjercicio(ejercicio);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final esNuevo = widget.ejercicio == null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          esNuevo ? 'Nuevo ejercicio' : 'Editar ejercicio',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _guardando ? null : _guardar,
              style: TextButton.styleFrom(
                backgroundColor:
                    _guardando ? AppTheme.border : AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Guardar',
                style: TextStyle(
                  color: _guardando ? AppTheme.textHint : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── FOTO DE LA MÁQUINA ────────────────────────
            Center(
              child: GestureDetector(
                onTap: _mostrarOpciones,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _imagenPath != null
                                ? Image.file(File(_imagenPath!),
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover)
                                : Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppTheme.primaryLight,
                                          Color(0xFFD6E8FA),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppTheme.primaryBorder,
                                          width: 1.5),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined,
                                            size: 44,
                                            color: AppTheme.primaryIcon),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Foto de la\nmáquina',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryIcon,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _imagenPath != null
                          ? 'Toca para cambiar la foto'
                          : 'Toca para agregar foto',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── NOMBRE ────────────────────────────────────
            const Text(
              'Nombre del ejercicio',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. Press de Pecho en Máquina',
                prefixIcon: Icon(Icons.fitness_center_outlined,
                    color: AppTheme.primaryIcon, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo requerido'
                  : null,
            ),
            const SizedBox(height: 24),

            // ── GRUPO MUSCULAR ────────────────────────────
            const Text(
              'Grupo muscular',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: _grupos.map((g) {
                final sel = g == _grupo;
                final color = AppTheme.grupoColor(g);
                final bgColor = AppTheme.grupoBgColor(g);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _grupo = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? color : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? color : AppTheme.border,
                            width: sel ? 0 : 0.5,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              g == 'Push'
                                  ? Icons.arrow_upward
                                  : g == 'Pull'
                                      ? Icons.arrow_downward
                                      : Icons.directions_walk,
                              size: 18,
                              color: sel ? Colors.white : color,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              g,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    sel ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // ── BOTÓN GUARDAR ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(
                        esNuevo ? Icons.add_circle_outline : Icons.save_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                label: Text(
                  esNuevo ? 'Crear ejercicio' : 'Guardar cambios',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
