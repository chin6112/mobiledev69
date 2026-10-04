import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';
import 'login_screen.dart';

/// Shows [child] only for a signed-in user; everyone else sees the login page.
class RouteGuard extends StatelessWidget {
  const RouteGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (context.watch<AuthViewModel>().status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return child;
    }
  }
}
