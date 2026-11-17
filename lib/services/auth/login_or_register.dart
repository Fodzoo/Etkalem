import 'package:etkalem/screens/registration_screen.dart';
import 'package:etkalem/screens/signin_screen.dart';
import 'package:flutter/material.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  static const String screenRoute = "LoginOrRegister";

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // Initially, show login screen.
  bool showLoginScreen = true;

  // Toggle between login and register screens.
  void togglePages() {
    setState(() {
      showLoginScreen = !showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginScreen) {
      return SigninScreen(onTap: togglePages);
    } else {
      return RegistrationScreen(onTap: togglePages);
    }
  }
}
