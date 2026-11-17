import 'package:etkalem/services/auth/auth_service.dart';
import 'package:etkalem/core/widgets/logo_body.dart';
import 'package:etkalem/core/widgets/my_button.dart';
import 'package:etkalem/core/widgets/my_textfield.dart';
import 'package:flutter/material.dart';

class RegistrationScreen extends StatefulWidget {
  final void Function()? onTap;

  const RegistrationScreen({super.key, this.onTap});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _pwController.text;
    final confirmPassword = _confirmPwController.text;

    if (name.isEmpty) {
      showMessage("Please enter your name");
      return;
    }

    if (email.isEmpty) {
      showMessage("Please enter your email");
      return;
    }

    if (password.isEmpty) {
      showMessage("Please enter your password");
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords don't match!");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final auth = AuthService();

      await auth.signUpWithEmailPassword(email, password, name);
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          message,
          style: TextStyle(color: colors.onSurface, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("OK", style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
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
                "Let's create an account for you",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 35),

              MyTextfield(
                hintText: "Name",
                obscureText: false,
                controller: _nameController,
              ),

              const SizedBox(height: 15),

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

              const SizedBox(height: 15),

              MyTextfield(
                hintText: "Confirm Password",
                obscureText: true,
                controller: _confirmPwController,
              ),

              const SizedBox(height: 30),

              MyButton(
                color: colors.primary,
                title: isLoading ? "Please wait..." : "Register",
                onPressed: isLoading ? null : register,
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: colors.onSurface),
                  ),

                  GestureDetector(
                    onTap: isLoading ? null : widget.onTap,
                    child: Text(
                      "Login now",
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
