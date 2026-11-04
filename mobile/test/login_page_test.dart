import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:immobilier_manager/core/error/failure.dart';
import 'package:immobilier_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:immobilier_manager/features/auth/presentation/pages/login_page.dart';
import 'package:immobilier_manager/features/auth/presentation/providers/auth_provider.dart';

class _FauxAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, void>> login(String username, String password) async =>
      const Left(AuthFailure('Identifiant ou mot de passe incorrect.'));

  @override
  Future<void> logout() async {}

  @override
  Future<bool> hasSession() async => false;

  @override
  Future<String?> currentUsername() async => null;
}

void main() {
  Widget app() => ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(_FauxAuthRepository())],
        child: const MaterialApp(home: LoginPage()),
      );

  testWidgets('les champs vides sont signalés sans appel réseau', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Identifiant obligatoire.'), findsOneWidget);
    expect(find.text('Mot de passe obligatoire.'), findsOneWidget);
  });

  testWidgets('un refus du serveur affiche son message', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextFormField).at(0), 'agent');
    await tester.enterText(find.byType(TextFormField).at(1), 'faux');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Identifiant ou mot de passe incorrect.'), findsOneWidget);
  });
}
