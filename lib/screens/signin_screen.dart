
import 'package:etkalem/services/auth/auth_service.dart';
import 'package:etkalem/core/widgets/logo_body.dart';
import 'package:etkalem/core/widgets/my_button.dart';
import 'package:etkalem/core/widgets/my_textfield.dart';
import 'package:flutter/material.dart';

class SigninScreen extends StatefulWidget {
  static const String screenRoute = "signin";

  final void Function()? onTap;

  const SigninScreen({super.key, this.onTap});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final authService = AuthService();

    setState(() {
      isLoading = true;
    });

    try {
      await authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _pwController.text,
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            e.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),

              const LogoBody(width: 130, height: 130),

              const SizedBox(height: 50),

              Text(
                "Welcome back, you've been missed!",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

              MyTextfield(
                hintText: "Email",
                obscureText: false,
                controller: _emailController,
              ),

              const SizedBox(height: 15),

              MyTextfield(
                hintText: "Password",
                obscureText: true,
                controller: _pwController,
              ),

              const SizedBox(height: 30),

              MyButton(
                color: colors.primary,
                title: isLoading ? "Please wait..." : "Log In",
                onPressed: isLoading ? null : login,
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Not a member? ",
                    style: TextStyle(
                      color: colors.onSurface,
                    ),
                  ),

                  GestureDetector(
                    onTap: isLoading ? null : widget.onTap,
                    child: Text(
                      "Register now",
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
