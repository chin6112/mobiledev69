import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_view_model.dart';
import 'features/auth/presentation/auth_view_model.dart';
import 'features/trip/data/trip_repository.dart';

class TripMateApp extends StatefulWidget {
  const TripMateApp({
    super.key,
    required this.authViewModel,
    required this.themeViewModel,
    required this.tripRepository,
  });

  final AuthViewModel authViewModel;
  final ThemeViewModel themeViewModel;
  final TripRepository tripRepository;

  @override
  State<TripMateApp> createState() => _TripMateAppState();
}

class _TripMateAppState extends State<TripMateApp> {
  late final GoRouter _router = createRouter(widget.authViewModel);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authViewModel),
        ChangeNotifierProvider.value(value: widget.themeViewModel),
        Provider.value(value: widget.tripRepository),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, theme, _) => MaterialApp.router(
          title: 'TripMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
