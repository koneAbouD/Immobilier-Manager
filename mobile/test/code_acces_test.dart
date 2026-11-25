import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:immobilier_manager/core/error/failure.dart';
import 'package:immobilier_manager/core/storage/secure_storage.dart';
import 'package:immobilier_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:immobilier_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:immobilier_manager/features/auth/presentation/providers/auth_state.dart';
import 'package:immobilier_manager/features/auth/presentation/providers/unlock_outcome.dart';
import 'package:tmk_pin/tmk_pin.dart';

/// Jeton d'accès factice : seules ses revendications sont lues.
String _jeton() {
  String partie(Map<String, Object> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${partie({'alg': 'none'})}.'
      '${partie({'preferred_username': '0700000000', 'given_name': 'Awa'})}.x';
}

/// Serveur d'authentification simulé, au-dessus du vrai stockage (mocké).
class _FauxAuth implements AuthRepository {
  final SecureStorage storage;
  Either<Failure, void> reouverture = const Right(null);
  int reouvertures = 0;

  _FauxAuth(this.storage);

  @override
  Future<Either<Failure, void>> login(String username, String password) async {
    await storage.saveTokens(accessToken: _jeton(), refreshToken: 'rt-login');
    await storage.saveUsername(username);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> inscrire({
    required String organisation,
    required String prenom,
    required String nom,
    String? email,
    required String telephone,
    required String motDePasse,
  }) =>
      login(telephone, motDePasse);

  @override
  Future<void> logout() => storage.clearTokens();

  @override
  Future<Either<Failure, void>> rouvrirSession(String refreshToken) async {
    reouvertures++;
    await storage.saveRefreshToken(refreshToken);
    if (reouverture.isRight()) {
      await storage.saveTokens(accessToken: _jeton(), refreshToken: 'rt-neuf');
    }
    return reouverture;
  }

  @override
  Future<bool> hasSession() async => (await storage.getRefreshToken()) != null;

  @override
  Future<String?> currentUsername() => storage.getUsername();
}

class _FausseBiometrie extends BiometricService {
  BiometricAvailability dispo = const BiometricAvailability(
    disponible: true,
    kind: BiometricKind.empreinte,
    libelle: 'empreinte digitale',
  );
  BiometricOutcome reponse = const BiometricAccepted();

  @override
  Future<BiometricAvailability> availability() async => dispo;

  @override
  Future<BiometricOutcome> authenticate({required String raison}) async =>
      reponse;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const code = '24680';
  late SecureStorage storage;
  late _FauxAuth serveur;
  late _FausseBiometrie biometrie;
  late PinService pin;

  AuthNotifier notifier() => AuthNotifier(
        serveur,
        pin: pin,
        biometrics: biometrie,
        storage: storage,
      );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'organisation_id': '1'});
    AuthNotifier.reinitialiserPourTests();
    storage = const SecureStorage();
    serveur = _FauxAuth(storage);
    biometrie = _FausseBiometrie();
    // Peu d'itérations : la dérivation réelle prend une seconde par essai.
    pin = PinService(PinStore(InMemoryKeyValueStore()), iterations: 1000);
  });

  /// Connexion puis choix du code : l'application est ouverte.
  Future<AuthNotifier> session() async {
    final auth = notifier();
    await auth.login('0700000000', 'secret');
    expect(auth.state, isA<AuthPinSetup>());
    expect(await auth.configurePin(code), isNull);
    expect(auth.state, isA<AuthAuthenticated>());
    return auth;
  }

  test('après la connexion, le code est obligatoire puis ouvre l\'application',
      () async {
    final auth = await session();
    expect(await pin.isConfigured(), isTrue);
    expect((auth.state as AuthAuthenticated).displayName, 'Awa');
  });

  test('un code devinable est refusé', () async {
    final auth = notifier();
    await auth.login('0700000000', 'secret');
    expect(await auth.configurePin('11111'), isNotNull);
    expect(await auth.configurePin('12345'), isNotNull);
    expect(auth.state, isA<AuthPinSetup>());
  });

  test('absence brève : pas de verrou ; longue : verrou, jetons effacés',
      () async {
    final auth = await session();
    auth.enArrierePlan();
    await auth.auPremierPlan(DateTime.now().add(const Duration(seconds: 5)));
    expect(auth.state, isA<AuthAuthenticated>());

    auth.enArrierePlan();
    await auth.auPremierPlan(DateTime.now().add(AuthNotifier.delaiDeGrace));
    expect(auth.state, isA<AuthLocked>());
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getOrganisationId(), 1,
        reason: 'le déverrouillage rouvre la même organisation');
  });

  test('code faux puis bon : la session est rouverte côté serveur', () async {
    final auth = await session();
    await auth.lock();

    expect(await auth.unlock('97531'), isA<UnlockWrong>());
    expect(await auth.unlock(code), isA<UnlockOk>());
    expect(auth.state, isA<AuthAuthenticated>());
    expect(serveur.reouvertures, 1);
  });

  test('serveur hors d\'atteinte : le bon code ouvre en consultation',
      () async {
    final auth = await session();
    await auth.lock();
    serveur.reouverture = const Left(NetworkFailure());

    expect(await auth.unlock(code), isA<UnlockOk>());
    expect(auth.state, isA<AuthAuthenticated>());
  });

  test('session révoquée : retour à la connexion, code gardé et redemandé',
      () async {
    final auth = await session();
    await auth.lock();
    serveur.reouverture = const Left(AuthFailure());

    expect(await auth.unlock(code), isA<UnlockRequiresLogin>());
    expect(auth.state, isA<AuthUnauthenticated>());
    expect(await pin.isConfigured(), isTrue);

    await auth.login('0700000000', 'secret');
    expect(auth.state, isA<AuthPinResume>());
    expect(await auth.resumePin(code), isA<UnlockOk>());
    expect(auth.state, isA<AuthAuthenticated>());
  });

  test('lancement à froid avec un code : écran de code, jetons effacés',
      () async {
    await session();
    AuthNotifier.reinitialiserPourTests(); // nouveau processus

    final auth = notifier();
    await auth.bootstrap();
    expect(auth.state, isA<AuthLocked>());
    expect(await storage.getRefreshToken(), isNull);
  });

  test('conteneur recréé dans le même processus : pas de nouveau code',
      () async {
    await session();
    final auth = notifier();
    await auth.bootstrap();
    expect(auth.state, isA<AuthAuthenticated>());
  });

  test('déconnexion : le code est conservé et redemandé à la connexion',
      () async {
    final auth = await session();
    await auth.logout();
    expect(auth.state, isA<AuthUnauthenticated>());

    final relance = notifier();
    await relance.bootstrap();
    expect(relance.state, isA<AuthUnauthenticated>(),
        reason: 'plus de session à rouvrir après une déconnexion');

    await relance.login('0700000000', 'secret');
    expect(relance.state, isA<AuthPinResume>());
  });

  group('biométrie', () {
    test('activée, elle rouvre l\'application sans le code', () async {
      final auth = await session();
      expect(await auth.enableBiometrics(), isNull);
      await auth.lock();

      expect(await auth.unlockWithBiometrics(), isA<UnlockOk>());
      expect(auth.state, isA<AuthAuthenticated>());
    });

    test('téléphone sans capteur : l\'activation explique pourquoi', () async {
      final auth = await session();
      biometrie.dispo = const BiometricAvailability(
        disponible: false,
        kind: BiometricKind.generique,
        libelle: 'déverrouillage biométrique',
        raison: 'Aucune donnée biométrique n\'est enregistrée sur cet '
            'appareil.',
      );
      expect(await auth.enableBiometrics(), contains('Aucune donnée'));
      expect(await auth.isBiometricsEnabled(), isFalse);
    });

    test('empreinte retirée du téléphone : l\'option tombe, le code reste',
        () async {
      final auth = await session();
      await auth.enableBiometrics();
      await auth.lock();
      biometrie.dispo = BiometricAvailability.indisponible;

      expect(await auth.unlockWithBiometrics(),
          isA<UnlockBiometricsFailed>());
      expect(await auth.isBiometricsEnabled(), isFalse);
      expect(await auth.unlock(code), isA<UnlockOk>());
    });

    test('annulée par l\'utilisateur : rien d\'ouvert, aucun essai perdu',
        () async {
      final auth = await session();
      await auth.enableBiometrics();
      await auth.lock();
      biometrie.reponse = const BiometricDismissed();

      expect(await auth.unlockWithBiometrics(),
          isA<UnlockBiometricsFailed>());
      expect(auth.state, isA<AuthLocked>());
      expect(await auth.unlock(code), isA<UnlockOk>());
    });

    test('proposée une seule fois après le choix du code', () async {
      final auth = await session();
      expect(await auth.biometricsToPropose(), isNotNull);
      await auth.markBiometricsProposed();
      expect(await auth.biometricsToPropose(), isNull);
    });
  });
}
