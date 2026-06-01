import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les notifications locales
  await NotificationService.init();

  // Vérifier si l'utilisateur est déjà connecté
  final authService = AuthService();
  final token = await authService.getToken();

  runApp(MyApp(
    initialScreen: token == null ? const LoginScreen() : const DashboardScreen(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initialScreen,
    );
  }
}