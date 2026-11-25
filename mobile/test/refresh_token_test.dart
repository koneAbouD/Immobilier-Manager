import 'dart:convert';

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
import 'package:immobilier_manager/core/storage/secure_storage.dart';

/// Refresh token : renouvellement réactif (401), proactif (avant expiration)
/// et distinction entre un vrai refus et une panne passagère — sur le modèle
/// de VTC Manager.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = SecureStorage();
  late int renouvellements;
  late int statutRefresh;
  late int expirations;
  late List<String> rechiffres;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'ancien',
      'refresh_token': 'rt-1',
    });
    renouvellements = 0;
    statutRefresh = 200;
    expirations = 0;
    rechiffres = [];
  });

  ApiClient client({int statutLecture = 200}) {
    final api = ApiClient(
      storage,
      MockClient((requete) async {
        if (requete.url.path.endsWith('/auth/refresh')) {
          renouvellements++;
          if (statutRefresh != 200) return http.Response('', statutRefresh);
          return http.Response(
              jsonEncode({
                'accessToken': 'neuf',
                'refreshToken': 'rt-${renouvellements + 1}',
                'expiresIn': 300,
              }),
              200);
        }
        final jeton = requete.headers['Authorization'];
        return http.Response('[]', jeton == 'Bearer neuf' ? 200 : statutLecture);
      }),
      EtatReseau(),
      DiagnosticReseau(
          sonde: () async => true, acces: () async => AccesReseau.wifi),
      ReponseCache(
        stockage: StockageMemoire(),
        chiffreur: ChiffreurCache.avecCle(List.filled(32, 1)),
      ),
    );
    api.onSessionExpired = () => expirations++;
    api.onTokensRenewed = rechiffres.add;
    return api;
  }

  test('401 : renouvelé, rejoué, coffre rechiffré, expiration mémorisée',
      () async {
    final api = client(statutLecture: 401);
    expect(await api.get('/biens'), <dynamic>[]);
    expect(renouvellements, 1);
    expect(await storage.getAccessToken(), 'neuf');
    expect(rechiffres, ['rt-2']);
    expect(await storage.getAccessTokenExpiry(), isNotNull);
    expect(expirations, 0);
  });

  test('refresh refusé (401) : la session est perdue', () async {
    statutRefresh = 401;
    final api = client(statutLecture: 401);
    await expectLater(api.get('/biens'), throwsA(isA<ApiException>()));
    expect(expirations, 1);
  });

  for (final statut in [500, 502, 503, 429]) {
    test('refresh en panne ($statut) : la session et les jetons restent',
        () async {
      statutRefresh = statut;
      final api = client(statutLecture: 401);
      await expectLater(api.get('/biens'), throwsA(isA<NetworkException>()));
      expect(expirations, 0);
      expect(await storage.getRefreshToken(), 'rt-1');
    });
  }

  test('jeton d\'accès expiré : renouvelé dès l\'ouverture de session',
      () async {
    await storage.saveTokens(
        accessToken: 'ancien', refreshToken: 'rt-1', expiresInSeconds: 0);
    final api = client()..demarrerRenouvellement();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(renouvellements, 1);
    expect(await storage.getAccessToken(), 'neuf');
    api.arreterRenouvellement();
  });

  test('session verrouillée : aucun renouvellement', () async {
    await storage.saveTokens(
        accessToken: 'ancien', refreshToken: 'rt-1', expiresInSeconds: 0);
    final api = client()
      ..demarrerRenouvellement()
      ..arreterRenouvellement();
    await api.renouvelerMaintenant();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(renouvellements, 0);
  });

  test('retour au premier plan hors ligne : pas de déconnexion', () async {
    final api = ApiClient(
      storage,
      MockClient((r) => throw http.ClientException('coupure', r.url)),
      EtatReseau(),
      DiagnosticReseau(
          sonde: () async => false, acces: () async => AccesReseau.aucun),
    )..onSessionExpired = () => expirations++;
    api.demarrerRenouvellement();
    await api.renouvelerMaintenant();
    expect(expirations, 0);
    expect(await storage.getRefreshToken(), 'rt-1');
    api.arreterRenouvellement();
  });
}
