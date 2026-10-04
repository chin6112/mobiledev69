import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/auth_view_model.dart';
import '../../features/auth/presentation/callback_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/trip/data/trip_repository.dart';
import '../../features/trip/presentation/trip_detail_screen.dart';
import '../../features/trip/presentation/trip_detail_view_model.dart';
import '../../features/trip/presentation/trip_list_screen.dart';
import '../../features/trip/presentation/trip_list_view_model.dart';

/// Every route except `/login` and `/callback` requires a signed-in user.
GoRouter createRouter(AuthViewModel auth) => GoRouter(
  refreshListenable: auth,
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/callback') return null;
    final signedIn = auth.status == AuthStatus.authenticated;
    if (!signedIn) return path == '/login' ? null : '/login';
    return path == '/login' ? '/' : null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/callback',
      builder: (context, state) => CallbackScreen(callbackUri: state.uri),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) =>
            TripListViewModel(context.read<TripRepository>())..load(),
        child: const TripListScreen(),
      ),
      routes: [
        GoRoute(
          path: 'trips/:id',
          builder: (context, state) => ChangeNotifierProvider(
            key: ValueKey(state.pathParameters['id']),
            create: (context) => TripDetailViewModel(
              context.read<TripRepository>(),
              int.parse(state.pathParameters['id']!),
            )..load(),
            child: const TripDetailScreen(),
          ),
        ),
      ],
    ),
  ],
);
