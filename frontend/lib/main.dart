import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/auth_repository.dart';
import 'repositories/trip_repository.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/trip_view_model.dart';
import 'views/callback_screen.dart';
import 'views/home_screen.dart';
import 'views/route_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final authRepository = AuthRepository(AuthService());
  final authViewModel = AuthViewModel(authRepository);
  final tripRepository = TripRepository(
    ApiService(
      accessToken: () => authRepository.accessToken,
      onUnauthorized: authViewModel.sessionExpired,
    ),
  );
  await authViewModel.restore();

  runApp(
    TripMateApp(authViewModel: authViewModel, tripRepository: tripRepository),
  );
}

class TripMateApp extends StatelessWidget {
  const TripMateApp({
    super.key,
    required this.authViewModel,
    required this.tripRepository,
  });

  final AuthViewModel authViewModel;
  final TripRepository tripRepository;

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    if (uri.path == '/callback') {
      return MaterialPageRoute(
        settings: const RouteSettings(name: '/callback'),
        builder: (_) => CallbackScreen(callbackUri: uri),
      );
    }
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/'),
      builder: (_) => RouteGuard(
        child: ChangeNotifierProvider(
          create: (context) =>
              TripViewModel(context.read<TripRepository>())..load(),
          child: const HomeScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        Provider.value(value: tripRepository),
      ],
      child: MaterialApp(
        title: 'TripMate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B87)),
          scaffoldBackgroundColor: const Color(0xFFF5F7F5),
          cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        ),
        onGenerateRoute: _onGenerateRoute,
        onGenerateInitialRoutes: (name) => [_onGenerateRoute(RouteSettings(name: name))],
      ),
    );
  }
}
