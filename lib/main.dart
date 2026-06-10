// ============================================================
// main.dart - GymTracker
// Punto de entrada de la aplicación de seguimiento de cargas
// progresivas para gimnasio. Se configura el idioma español para
// mostrar correctamente el historial de entrenamientos y
// lanza la aplicación iniciando en la pantalla de Login.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // Lanza GymTracker mostrando primero la pantalla de Login
  // para que el usuario acceda a su perfil de entrenamiento
  runApp(const GymTrackerApp());
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymTracker',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),// Se carga primero el login
    );
  }
}
