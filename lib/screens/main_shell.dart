// ============================================================
// main_shell.dart - GymTracker
// Contenedor principal de la aplicación después del Login.
// Maneja la navegación entre las dos secciones principales:
// - Inicio: resumen de los últimos entrenamientos del usuario
// - Ejercicios: catálogo completo de ejercicios del gimnasio
// Usa una barra de navegación inferior para cambiar entre
// secciones manteniendo el estado de cada pantalla activa.
// ============================================================

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'ejercicios_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    EjerciciosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),

      // ── BARRA DE NAVEGACIÓN INFERIOR ─────────────────────
      // Permite al usuario moverse entre Inicio y Ejercicios
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: Color(0x22000000), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF185FA5),
          unselectedItemColor: const Color(0xFF888780),
          elevation: 0,
          items: const [

            // ── PESTAÑA INICIO ────────────────────────────
            // Muestra el resumen de los últimos entrenamientos
            // con estadísticas y sesiones recientes del usuario
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),

            // ── PESTAÑA EJERCICIOS ────────────────────────
            // Muestra el catálogo completo de ejercicios
            // con filtros por grupo muscular Push/Pull/Pierna
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Ejercicios',
            ),
          ],
        ),
      ),
    );
  }
}
