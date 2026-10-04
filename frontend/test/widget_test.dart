import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/repositories/auth_repository.dart';
import 'package:frontend/repositories/trip_repository.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/viewmodels/auth_view_model.dart';

class _SignedOutRepository extends AuthRepository {
  _SignedOutRepository() : super(AuthService());

  @override
  Future<bool> restoreSession() async => false;
}

void main() {
  testWidgets('route guard shows OIDC login when signed out', (tester) async {
    final auth = AuthViewModel(_SignedOutRepository());
    await auth.restore();
    final trips = TripRepository(
      ApiService(accessToken: () => null, onUnauthorized: () async {}),
    );

    await tester.pumpWidget(
      TripMateApp(authViewModel: auth, tripRepository: trips),
    );
    await tester.pump();

    expect(find.text('เข้าสู่ TripMate'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบด้วย OIDC'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
  });
}
