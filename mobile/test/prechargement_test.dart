import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:immobilier_manager/core/cache/chiffreur_cache.dart';
import 'package:immobilier_manager/core/cache/reponse_cache.dart';
import 'package:immobilier_manager/core/cache/stockage_reponses.dart';
import 'package:immobilier_manager/core/error/exception.dart';
import 'package:immobilier_manager/core/network/api_client.dart';
import 'package:immobilier_manager/core/network/diagnostic_reseau.dart';
import 'package:immobilier_manager/core/network/etat_reseau.dart';
import 'package:immobilier_manager/core/network/prechargement.dart';
import 'package:immobilier_manager/core/providers/core_providers.dart';
import 'package:immobilier_manager/core/storage/secure_storage.dart';
import 'package:immobilier_manager/features/immeuble/presentation/providers/immeuble_providers.dart';
import 'package:immobilier_manager/features/locataire/presentation/providers/locataire_providers.dart';
import 'package:immobilier_manager/features/organisation/presentation/providers/organisation_providers.dart';
import 'package:immobilier_manager/features/tableau_bord/presentation/providers/tableau_bord_providers.dart';

/// Écrans lus d'avance : ils doivent être servis hors connexion sans avoir été
/// ouverts, ce qui suppose de lire exactement leurs URL.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EtatReseau etat;
  late ReponseCache cache;
  late List<Uri> demandes;
  late bool enLigne;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'jeton',
      'refresh_token': 'renouvellement',
      'username': '0700000000',
      'organisation_id': '1',
    });
    etat = EtatReseau();
    cache = ReponseCache(
      stockage: StockageMemoire(),
      chiffreur: ChiffreurCache.avecCle(List.filled(32, 3)),
    );
    demandes = [];
    enLigne = true;
  });

  ApiClient client() => ApiClient(
        const SecureStorage(),
        MockClient((requete) async {
          demandes.add(requete.url);
          if (!enLigne) {
            throw http.ClientException('coupure', requete.url);
          }
          return http.Response('{}', 200);
        }),
        etat,
        DiagnosticReseau(
            sonde: () async => false, acces: () async => AccesReseau.aucun),
        cache,
      );

  Future<void> ecrituresFaites() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('une lecture préchargée est servie hors connexion', () async {
    final api = client();
    await ApiClient.precharger(() => api.get('/immeubles'));
    await ecrituresFaites();
    expect(etat.value, isNull);

    enLigne = false;
    expect(await api.get('/immeubles'), <String, dynamic>{});
  });

  test('sans réseau, le préchargement ne pose ni bandeau ni secours', () async {
    final api = client();
    await api.get('/immeubles');
    await ecrituresFaites();

    enLigne = false;
    await expectLater(ApiClient.precharger(() => api.get('/immeubles')),
        throwsA(isA<NetworkException>()));
    expect(etat.value, isNull);
  });

  test('un préchargement réussi n\'efface pas le bandeau des écrans', () async {
    final api = client();
    etat.donneesDuCache(DateTime.now(), CauseIndisponibilite.reseau);
    await ApiClient.precharger(() => api.get('/immeubles'));
    expect(etat.value, CauseIndisponibilite.reseau);
  });

  Future<WidgetRef> monter(WidgetTester tester, ApiClient api) async {
    late WidgetRef capture;
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: Consumer(builder: (context, ref, _) {
        capture = ref;
        return const SizedBox();
      }),
    ));
    return capture;
  }

  testWidgets('les URL préchargées sont celles que lisent les écrans',
      (tester) async {
    final api = client();
    final ref = await monter(tester, api);

    await tester.runAsync(() => prechargerEcransCles(ref));
    final prechargees = demandes.map((u) => u.toString()).toSet();
    expect(prechargees, hasLength(12));

    // Ce que demandent les écrans eux-mêmes à leur ouverture.
    demandes.clear();
    final container = ProviderScope.containerOf(tester.element(find.byType(SizedBox)));
    for (final ecran in <ProviderListenable<AsyncValue<Object?>>>[
      tableauBordProvider,
      accueilRetardsProvider,
      accueilAEncaisserProvider,
      accueilPaiementsProvider,
      immeublesListeProvider,
      comptesSituationsProvider(''),
      organisationCouranteProvider,
    ]) {
      final abonnement = container.listen(ecran, (_, _) {});
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 20)));
      abonnement.close();
    }
    expect(demandes, isNotEmpty);
    for (final url in demandes) {
      expect(prechargees, contains(url.toString()),
          reason: 'écran non préchargé : $url');
    }
  });

  testWidgets('serveur hors d\'atteinte : on s\'arrête à la première lecture',
      (tester) async {
    enLigne = false;
    final ref = await monter(tester, client());
    await tester.runAsync(() => prechargerEcransCles(ref));
    expect(demandes, hasLength(1));
    expect(etat.value, isNull);
  });
}
