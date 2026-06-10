// ============================================================
// ejercicio_image.dart - GymTracker
// Widget reutilizable que muestra la imagen de un ejercicio.
// Tiene tres comportamientos según la disponibilidad de imagen:
// 1. Muestra la foto tomada por el usuario a la máquina
// 2. Muestra una imagen predefinida de los assets de la app
// 3. Muestra un placeholder con la letra inicial del ejercicio
//    en el color del grupo muscular (Push=azul, Pull=verde,
//    Pierna=naranja) cuando no hay ninguna foto disponible
// Se usa en la lista de ejercicios, en el inicio y en el detalle
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ejercicio.dart';
import '../utils/app_theme.dart';

// Widget que muestra la imagen asociada a un ejercicio del gimnasio
class EjercicioImage extends StatelessWidget {
  final Ejercicio ejercicio;
  final double size;
  final BorderRadius? borderRadius;

  const EjercicioImage({
    super.key,
    required this.ejercicio,
    this.size = 52,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(10);

    // ── PRIORIDAD 1: Foto tomada por el usuario ───────────────
    // Si el usuario fotografió la máquina de su gimnasio
    // muestra esa foto cargándola desde el sistema de archivos
    if (ejercicio.imagenPath != null) {
      return ClipRRect(
        borderRadius: br,
        child: Image.file(
          File(ejercicio.imagenPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(br),
        ),
      );
    }

    // ── PRIORIDAD 2 y 3: Placeholder ─────────────────────────
    // Si no hay foto del usuario ni imagen predefinida
    // muestra un cuadrado de color con la letra inicial
    return _placeholder(br);
  }

  // Construye el placeholder cuando no hay foto disponible
  // Muestra la primera letra del nombre del ejercicio
  Widget _placeholder(BorderRadius br) {
    final letter =
        ejercicio.nombre.isNotEmpty ? ejercicio.nombre[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: br,
      child: Container(
        width: size,
        height: size,
        color: AppTheme.grupoBgColor(ejercicio.grupo),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w500,
              color: AppTheme.grupoColor(ejercicio.grupo),
            ),
          ),
        ),
      ),
    );
  }
}
