import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/auth/auth_service.dart';
import 'package:frontend/core/result/result.dart';
import 'package:frontend/core/theme/theme_view_model.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/presentation/auth_view_model.dart';
import 'package:frontend/features/trip/data/trip_repository.dart';
import 'package:frontend/features/trip/domain/trip_models.dart';
import 'package:frontend/features/trip/presentation/trip_list_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedOutRepository extends AuthRepository {
  _SignedOutRepository() : super(AuthService());

  @override
  Future<bool> restoreSession() async => false;
}

class _StubTripRepository extends TripRepository {
  _StubTripRepository(this.trips) : super(_unusedApi());

  final List<Trip> trips;

  static ApiClient _unusedApi() =>
      ApiClient(accessToken: () => null, onUnauthorized: () async {}, dio: Dio());

  @override
  Future<Result<List<Trip>>> getTrips() async => Ok(trips);
}

Trip _trip(int id, String title, String destination, DateTime start) => Trip(
  id: id,
  title: title,
  destination: destination,
  startDate: start,
  endDate: start.add(const Duration(days: 2)),
  status: 'upcoming',
  owner: 'demo',
  memberNames: const ['demo'],
);

void main() {
  testWidgets('route guard sends signed-out users to the OIDC login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthViewModel(_SignedOutRepository());
    await auth.restore();

    await tester.pumpWidget(
      TripMateApp(
        authViewModel: auth,
        themeViewModel: ThemeViewModel(await SharedPreferences.getInstance()),
        tripRepository: _StubTripRepository(const []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบด้วย OIDC'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
  });

  test('Result.guard converts AppException into Err', () async {
    final result = await Result.guard<int>(
      () async => throw const AppException('boom', 500),
    );
    expect(result.errorMessage, 'boom');
    expect(result.valueOrNull, isNull);
    expect((await Result.guard(() async => 3)).valueOrNull, 3);
  });

  test('trip list filters by query and sorts', () async {
    final viewModel = TripListViewModel(
      _StubTripRepository([
        _trip(1, 'Beach', 'Krabi', DateTime(2026, 1, 1)),
        _trip(2, 'Hiking', 'Chiang Mai', DateTime(2026, 6, 1)),
        _trip(3, 'City', 'Bangkok', DateTime(2026, 3, 1)),
      ]),
    );
    await viewModel.load();

    expect(viewModel.visibleTrips.map((t) => t.id), [2, 3, 1]);
    viewModel.setSort(TripSort.titleAZ);
    expect(viewModel.visibleTrips.map((t) => t.id), [1, 3, 2]);
    viewModel.setQuery('chiang');
    expect(viewModel.visibleTrips.map((t) => t.id), [2]);
  });

  test('dark mode preference is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeViewModel(prefs);
    expect(theme.isDark, isFalse);
    await theme.toggle();
    expect(ThemeViewModel(prefs).isDark, isTrue);
  });
}
