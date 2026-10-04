import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';

/// Handles the redirect from the OIDC provider (`/callback?code=...`).
class CallbackScreen extends StatefulWidget {
  const CallbackScreen({super.key, required this.callbackUri});

  final Uri callbackUri;

  @override
  State<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends State<CallbackScreen> {
  late final Future<bool> _result = context
      .read<AuthViewModel>()
      .completeLogin(widget.callbackUri);

  void _goHome() => Navigator.of(context).pushReplacementNamed('/');

  @override
  void initState() {
    super.initState();
    _result.then((ok) {
      if (ok && mounted) _goHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<bool>(
          future: _result,
          builder: (context, snapshot) {
            if (snapshot.data == false) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.read<AuthViewModel>().error ??
                          'เข้าสู่ระบบไม่สำเร็จ',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _goHome,
                      child: const Text('กลับไปหน้าเข้าสู่ระบบ'),
                    ),
                  ],
                ),
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
