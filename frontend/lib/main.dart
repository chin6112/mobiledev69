import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_service.dart';
import 'core/theme/theme_view_model.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_view_model.dart';
import 'features/trip/data/trip_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final authRepository = AuthRepository(AuthService());
  final authViewModel = AuthViewModel(authRepository);
  final tripRepository = TripRepository(
    ApiClient(
      accessToken: () => authRepository.accessToken,
      onUnauthorized: authViewModel.sessionExpired,
    ),
  );
  final themeViewModel = ThemeViewModel(await SharedPreferences.getInstance());
  await authViewModel.restore();

  runApp(
    TripMateApp(
      authViewModel: authViewModel,
      themeViewModel: themeViewModel,
      tripRepository: tripRepository,
    ),
  );
}
