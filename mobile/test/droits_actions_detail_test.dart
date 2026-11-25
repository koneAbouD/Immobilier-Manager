import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:immobilier_manager/core/app/droits.dart';
import 'package:immobilier_manager/core/network/api_client.dart';
import 'package:immobilier_manager/core/providers/core_providers.dart';
import 'package:immobilier_manager/core/storage/secure_storage.dart';
import 'package:immobilier_manager/core/widgets/app_header.dart';

/// Affichage des actions « Modifier » et « Supprimer » d'une fiche selon le
/// rôle, l'abonnement et l'état de la donnée (matrice `ActionMetier`).
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({'access_token': 'jeton'}));

  Future<void> afficher(
    WidgetTester tester, {
    required RoleMembre role,
    bool ecritureOuverte = true,
    ActionMetier droit = ActionMetier.supprimerBien,
    Map<String, dynamic> etat = const {'possible': true},
    VoidCallback? onSupprimer,
  }) async {
    final api = ApiClient(const SecureStorage(),
        MockClient((_) async => http.Response(jsonEncode(etat), 200,
            headers: {'content-type': 'application/json; charset=utf-8'})));
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp(
        home: Droits(
          role: role,
          ecritureOuverte: ecritureOuverte,
          child: Scaffold(
            body: Center(
              child: ActionsDetail(
                onModifier: () {},
                onSupprimer: onSupprimer ?? () {},
                droitSuppression: droit,
                ressource: '/immeubles/1',
              ),
            ),
          ),
        ),
      ),
    ));
  }

  final menu = find.byIcon(Icons.more_horiz_rounded);
  final modifier = find.text('Modifier');

  testWidgets('lecteur : consultation seule', (tester) async {
    await afficher(tester, role: RoleMembre.lecteur);
    expect(modifier, findsNothing);
    expect(menu, findsNothing);
  });

  testWidgets('gestionnaire : modifie un bien sans pouvoir le supprimer', (tester) async {
    await afficher(tester, role: RoleMembre.gestionnaire);
    expect(modifier, findsOneWidget);
    expect(menu, findsNothing);
  });

  testWidgets('gestionnaire : supprime un locataire', (tester) async {
    await afficher(tester, role: RoleMembre.gestionnaire, droit: ActionMetier.supprimerLocataire);
    expect(menu, findsOneWidget);
  });

  testWidgets('administrateur : supprime un bien', (tester) async {
    await afficher(tester, role: RoleMembre.admin);
    expect(modifier, findsOneWidget);
    expect(menu, findsOneWidget);
  });

  testWidgets('abonnement en lecture seule : rien, même pour le propriétaire', (tester) async {
    await afficher(tester, role: RoleMembre.proprietaire, ecritureOuverte: false);
    expect(modifier, findsNothing);
    expect(menu, findsNothing);
  });

  testWidgets('suppression bloquée : grisée, avec le motif du serveur', (tester) async {
    var supprime = false;
    await afficher(tester,
        role: RoleMembre.admin,
        etat: {'possible': false, 'code': 'IMMEUBLE_NON_VIDE', 'motif': 'Supprimez d\'abord ses locaux.'},
        onSupprimer: () => supprime = true);
    await tester.tap(menu);
    await tester.pumpAndSettle();

    expect(find.text('Supprimez d\'abord ses locaux.'), findsOneWidget);
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(supprime, isFalse);
  });

  testWidgets('suppression possible : le menu la lance', (tester) async {
    var supprime = false;
    await afficher(tester, role: RoleMembre.admin, onSupprimer: () => supprime = true);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(supprime, isTrue);
  });
}
