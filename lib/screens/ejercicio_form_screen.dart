// ============================================================
// ejercicio_form_screen.dart - GymTracker
// Pantalla para crear o editar un ejercicio del catálogo.
// Permite al usuario ingresar el nombre del ejercicio,
// seleccionar el grupo muscular (Push/Pull/Pierna) y agregar
// una foto de la máquina tomada directamente con la cámara
// del celular o seleccionada desde la galería de fotos.
// Esta funcionalidad es clave para que el usuario identifique
// visualmente cada máquina de su gimnasio específico.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../models/ejercicio.dart';
import '../utils/app_theme.dart';

// Pantalla de formulario para crear o editar ejercicios
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

  // Si se está editando un ejercicio existente
  // pre-llena los campos con sus datos actuales
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

  // Abre la cámara o galería para seleccionar la foto
  // de la máquina del ejercicio en el gimnasio del usuario
  Future<void> _seleccionarImagen(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(

        // Comprime la imagen al 80% para ahorrar espacio
        // sin pérdida visual notable en la pantalla del celular
        source: source, imageQuality: 80, maxWidth: 800);

    // Actualiza la foto mostrada si el usuario seleccionó una
    if (picked != null) setState(() => _imagenPath = picked.path);
  }

  // Muestra el menú inferior con opciones para agregar
  // la foto de la máquina del ejercicio en el gimnasio
  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),

            // ── OPCIÓN CÁMARA ─────────────────────────────
            // Abre la cámara para fotografiar la máquina
            // directamente en el gimnasio del usuario
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.primary),
              title: const Text('Tomar foto a la máquina'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),

            // ── OPCIÓN GALERÍA ────────────────────────────
            // Permite seleccionar una foto ya tomada
            // de la galería del celular del usuario
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primary),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),

            // ── OPCIÓN ELIMINAR FOTO ──────────────────────
            // Solo visible si ya hay una foto asignada
            // Permite quitar la foto de la máquina
            if (_imagenPath != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Eliminar foto',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagenPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Guarda el ejercicio en la base de datos SQLite
  // Si es nuevo lo inserta, si existe lo actualiza
  // Regresa a la pantalla anterior al terminar
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
        title: Text(esNuevo ? 'Nuevo ejercicio' : 'Editar ejercicio'),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: _guardando ? AppTheme.textHint : AppTheme.primary,
                fontWeight: FontWeight.w500,
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
            // Foto de la máquina
            Center(
              child: GestureDetector(
                onTap: _mostrarOpciones,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _imagenPath != null
                          ? Image.file(File(_imagenPath!),
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover)
                          : Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppTheme.primaryBorder,
                                    style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: AppTheme.primaryIcon),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Foto de la máquina',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryIcon),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
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
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Toca para agregar o cambiar foto',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            const Text(
              'Nombre del ejercicio',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. Press de Pecho en Máquina',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Campo requerido'
                  : null,
            ),
            const SizedBox(height: 20),

            // Grupo muscular
            const Text(
              'Grupo muscular',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: _grupos.map((g) {
                final sel = g == _grupo;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _grupo = g),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppTheme.primary
                                : AppTheme.border,
                          ),
                        ),
                        child: Text(
                          g,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: sel
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(esNuevo
                        ? 'Crear ejercicio'
                        : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
