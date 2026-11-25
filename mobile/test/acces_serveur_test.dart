import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:immobilier_manager/core/widgets/bandeau_hors_ligne.dart';

/// Serveur hors d'atteinte : le message et le bandeau disent pourquoi (accès
/// coupé, internet absent, serveur en panne) et quoi faire.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EtatReseau etat;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'jeton',
      'refresh_token': 'renouvellement',
    });
    etat = EtatReseau();
  });

  ApiClient client(
    Future<http.Response> Function(http.Request) serveur, {
    AccesReseau acces = AccesReseau.wifi,
    bool internet = true,
  }) =>
      ApiClient(
        const SecureStorage(),
        MockClient(serveur),
        etat,
        DiagnosticReseau(sonde: () async => internet, acces: () async => acces),
        // Cache vierge : ces tests portent sur le message, pas sur le secours.
        ReponseCache(
          stockage: StockageMemoire(),
          chiffreur: ChiffreurCache.avecCle(List.filled(32, 0)),
        ),
      );

  Future<NetworkException> echec(Future<dynamic> appel) async {
    try {
      await appel;
    } on NetworkException catch (e) {
      return e;
    }
    fail('une NetworkException était attendue');
  }

  http.ClientException coupure(int code) => _CoupureSocket(code);

  test('Wi-Fi et données coupés : il faut en activer un', () async {
    final e = await echec(client((_) => throw coupure(0),
            acces: AccesReseau.aucun)
        .get('/biens'));
    expect(e.cause, CauseIndisponibilite.reseauDesactive);
    expect(e.message, kMsgReseauDesactive);
    expect(etat.value, CauseIndisponibilite.reseauDesactive);
  });

  test('données mobiles sans internet', () async {
    final e = await echec(client((_) => throw coupure(0),
            acces: AccesReseau.donneesMobiles, internet: false)
        .get('/biens'));
    expect(e.message, kMsgDonneesSansInternet);
  });

  test('Wi-Fi sans internet', () async {
    final e = await echec(client((_) => throw coupure(0),
            acces: AccesReseau.wifi, internet: false)
        .get('/biens'));
    expect(e.message, kMsgWifiSansInternet);
  });

  test('internet fonctionne mais pas le serveur : patienter', () async {
    final e = await echec(
        client((_) => throw coupure(0), internet: true).get('/biens'));
    expect(e.cause, CauseIndisponibilite.serveur);
    expect(e.message, kMsgServeurInjoignable);
  });

  test('connexion refusée : le serveur, sans sonder', () async {
    var sondes = 0;
    final api = ApiClient(
      const SecureStorage(),
      MockClient((_) => throw _CoupureSocket(111)),
      etat,
      DiagnosticReseau(sonde: () async {
        sondes++;
        return false;
      }, acces: () async => AccesReseau.wifi),
      ReponseCache(
        stockage: StockageMemoire(),
        chiffreur: ChiffreurCache.avecCle(List.filled(32, 0)),
      ),
    );
    final e = await echec(api.get('/biens'));
    expect(e.cause, CauseIndisponibilite.serveur);
    expect(sondes, 0);
  });

  test('redirection (portail Wi-Fi) : accès détourné', () async {
    final e = await echec(client((_) async => http.Response('', 302,
        headers: {'location': 'http://portail/'})).get('/biens'));
    expect(e.message, kMsgAccesDetourne);
    expect(etat.value, CauseIndisponibilite.reseau);
  });

  test('503 : serveur indisponible, bandeau posé', () async {
    await expectLater(
        client((_) async => http.Response('', 503)).get('/biens'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', kMsgServeurIndisponible)));
    expect(etat.value, CauseIndisponibilite.serveur);
  });

  test('le serveur répond : le bandeau s\'efface', () async {
    etat.injoignable(CauseIndisponibilite.reseau);
    await client((_) async => http.Response('[]', 200)).get('/biens');
    expect(etat.value, isNull);
  });

  test('coupure pendant le renouvellement : pas de déconnexion', () async {
    var expirations = 0;
    final api = client((requete) async {
      if (requete.url.path.endsWith('/auth/refresh')) throw coupure(0);
      return http.Response('', 401);
    }, acces: AccesReseau.aucun)
      ..onSessionExpired = () => expirations++;

    final e = await echec(api.get('/biens'));
    expect(e.cause, CauseIndisponibilite.reseauDesactive);
    expect(expirations, 0);
  });

  test('bascules Wi-Fi / données : le bandeau suit l\'accès', () {
    etat.accesChange(AccesReseau.aucun);
    expect(etat.value, CauseIndisponibilite.reseauDesactive);
    etat.accesChange(AccesReseau.donneesMobiles);
    expect(etat.value, isNull);
  });

  testWidgets('le bandeau dit la cause et s\'efface au retour', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BandeauHorsLigne(
        etat: etat,
        child: const Scaffold(body: Text('Accueil')),
      ),
    ));
    expect(find.textContaining('Wi-Fi et données coupés'), findsNothing);

    etat.injoignable(CauseIndisponibilite.reseauDesactive);
    await tester.pump();
    expect(find.text('Wi-Fi et données coupés · activez l\'un des deux'),
        findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);

    etat.joignable();
    await tester.pump();
    expect(find.textContaining('Wi-Fi et données coupés'), findsNothing);
  });

  group('cache hors connexion', () {
    late ReponseCache cache;
    var enLigne = true;

    setUp(() {
      enLigne = true;
      cache = ReponseCache(
        stockage: StockageMemoire(),
        chiffreur: ChiffreurCache.avecCle(List.filled(32, 7)),
      );
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'jeton',
        'refresh_token': 'renouvellement',
        'username': '0700000000',
        'organisation_id': '1',
      });
    });

    ApiClient api(Future<http.Response> Function(http.Request) serveur) =>
        ApiClient(
          const SecureStorage(),
          MockClient((r) async {
            if (!enLigne) throw _CoupureSocket(0);
            return serveur(r);
          }),
          etat,
          DiagnosticReseau(
              sonde: () async => false, acces: () async => AccesReseau.aucun),
          cache,
        );

    /// Laisse l'écriture en cache (non attendue) se terminer.
    Future<void> ecrituresFaites() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    test('sans réseau, la dernière réponse est rejouée et datée', () async {
      final client = api((_) async => http.Response('[{"nom":"A01"}]', 200));
      expect(await client.get('/biens'), [
        {'nom': 'A01'}
      ]);
      await ecrituresFaites();

      enLigne = false;
      expect(await client.get('/biens'), [
        {'nom': 'A01'}
      ]);
      expect(etat.value, CauseIndisponibilite.reseauDesactive);
      expect(etat.donneesDu, isNotNull);

      enLigne = true;
      await client.get('/biens');
      expect(etat.value, isNull);
      expect(etat.donneesDu, isNull);
    });

    test('rien en cache : l\'erreur réseau remonte', () async {
      enLigne = false;
      final e = await echec(api((_) async => http.Response('[]', 200))
          .get('/biens'));
      expect(e.message, kMsgReseauDesactive);
    });

    test('une autre organisation ne voit pas les réponses de la première',
        () async {
      final client = api((_) async => http.Response('["org1"]', 200));
      await client.get('/biens');
      await ecrituresFaites();

      await const SecureStorage().setOrganisationId(2);
      enLigne = false;
      await echec(client.get('/biens'));
    });

    test('un autre compte ne voit pas les réponses du premier', () async {
      final client = api((_) async => http.Response('["moi"]', 200));
      await client.get('/biens');
      await ecrituresFaites();

      await const SecureStorage().saveUsername('0611111111');
      enLigne = false;
      await echec(client.get('/biens'));
    });

    test('une erreur du serveur n\'est jamais masquée par le cache', () async {
      var statut = 200;
      final client = api((_) async => http.Response('["A01"]', statut));
      await client.get('/biens');
      await ecrituresFaites();

      statut = 404;
      await expectLater(client.get('/biens'), throwsA(isA<ApiException>()));
    });

    test('503 : la dernière réponse est rejouée', () async {
      var statut = 200;
      final client = api((_) async => http.Response('["A01"]', statut));
      await client.get('/biens');
      await ecrituresFaites();

      statut = 503;
      expect(await client.get('/biens'), ['A01']);
      expect(etat.value, CauseIndisponibilite.serveur);
    });

    test('l\'authentification ne passe jamais par le cache', () async {
      final client = api((_) async => http.Response('{"ok":true}', 200));
      await client.get('/auth/moi');
      await ecrituresFaites();
      enLigne = false;
      await echec(client.get('/auth/moi'));
    });
  });

  test('le bandeau date les données rejouées', () {
    final le = DateTime(2026, 11, 25, 14, 32);
    expect(
        libelleHorsLigne(CauseIndisponibilite.reseau,
            donneesDu: le, maintenant: DateTime(2026, 11, 25, 18)),
        'Hors connexion · données de 14:32');
    expect(
        libelleHorsLigne(CauseIndisponibilite.serveur,
            donneesDu: le, maintenant: DateTime(2026, 11, 26, 9)),
        'Serveur indisponible · données d\'hier à 14:32');
    expect(
        libelleHorsLigne(CauseIndisponibilite.wifiSansInternet,
            donneesDu: le, maintenant: DateTime(2026, 11, 30)),
        'Wi-Fi sans internet · données du 25/11 à 14:32');
  });
}

/// Ce que lève `IOClient` sur une erreur de socket : une [http.ClientException]
/// qui est aussi la [SocketException] d'origine, code système compris.
class _CoupureSocket extends http.ClientException implements SocketException {
  final int code;

  _CoupureSocket(this.code) : super('coupure', Uri.parse('http://serveur/'));

  @override
  OSError? get osError => OSError('coupure', code);

  @override
  InternetAddress? get address => null;

  @override
  int? get port => null;
}
