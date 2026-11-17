import 'package:etkalem/firebase_options.dart';
import 'package:etkalem/screens/splash_screen.dart';
import 'package:etkalem/services/auth/auth_gate.dart';
import 'package:etkalem/services/auth/login_or_register.dart';
import 'package:etkalem/themes/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:etkalem/services/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Etkalem App',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        LoginOrRegister.screenRoute: (context) => const LoginOrRegister(),
        AuthGate.screenRoute: (context) => const AuthGate(),
      },
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
