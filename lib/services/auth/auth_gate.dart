import 'dart:async';
import 'package:etkalem/screens/home/home_screen.dart';
import 'package:etkalem/services/auth/login_or_register.dart';
import 'package:etkalem/services/auth/presence_service.dart';
import 'package:etkalem/services/notifications/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const String screenRoute = 'AuthGate';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return PresenceWrapper(key: ValueKey(user.uid), uid: user.uid);
        }

        return const LoginOrRegister();
      },
    );
  }
}

class PresenceWrapper extends StatefulWidget {
  final String uid;

  const PresenceWrapper({super.key, required this.uid});

  @override
  State<PresenceWrapper> createState() => _PresenceWrapperState();
}

class _PresenceWrapperState extends State<PresenceWrapper>
    with WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    unawaited(_presenceService.startPresence(widget.uid));

    unawaited(NotificationService.registerToken(widget.uid));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(NotificationService.onUserAuthenticated(widget.uid));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_presenceService.startPresence(widget.uid));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_presenceService.setOffline());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_presenceService.stopPresence());
    unawaited(NotificationService.stopTokenRefreshListener());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }
}
