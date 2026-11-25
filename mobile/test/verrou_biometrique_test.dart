import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/providers/core_providers.dart';
import 'package:immobilier_manager/core/security/biometric_service.dart';
import 'package:immobilier_manager/core/storage/secure_storage.dart';
import 'package:immobilier_manager/features/auth/presentation/pages/verrou_biometrique_page.dart';
import 'package:immobilier_manager/features/auth/presentation/providers/verrou_biometrique.dart';
import 'package:immobilier_manager/features/auth/presentation/widgets/proposition_biometrie.dart';

/// Biométrie simulée : disponibilité et réponse de l'OS au choix du test.
class _FausseBiometrie extends BiometricService {
  BiometricAvailability dispo = const BiometricAvailability(
    disponible: true,
    kind: BiometricKind.empreinte,
    libelle: 'empreinte digitale',
  );
  BiometricOutcome reponse = const BiometricAccepted();
  int demandes = 0;

  @override
  Future<BiometricAvailability> availability() async => dispo;

  @override
  Future<BiometricOutcome> authenticate({required String raison}) async {
    demandes++;
    return reponse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FausseBiometrie biometrie;
  late SecureStorage storage;
  late VerrouBiometriqueNotifier verrou;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'username': '0700000000'});
    VerrouBiometriqueNotifier.reinitialiserPourTests();
    biometrie = _FausseBiometrie();
    storage = const SecureStorage();
    verrou = VerrouBiometriqueNotifier(storage, biometrie);
  });

  test('option coupée : le lancement ne verrouille pas', () async {
    await verrou.preparerDemarrage();
    expect(verrou.state, Verrou.ouvert);
  });

  test('l\'activation exige la biométrie et se rattache au compte', () async {
    expect(await verrou.activer(), isNull);
    expect(biometrie.demandes, 1);
    expect(await storage.getBiometrieCompte(), '0700000000');
    expect(await verrou.estActif(), isTrue);
  });

  test('activation refusée par l\'OS : l\'option reste coupée', () async {
    biometrie.reponse = const BiometricDismissed();
    expect(await verrou.activer(), isNotNull);
    expect(await verrou.estActif(), isFalse);
  });

  test('option active : le lancement verrouille, la biométrie ouvre', () async {
    await storage.setBiometrieCompte('0700000000');
    await verrou.preparerDemarrage();
    expect(verrou.state, Verrou.demarrage);

    expect(await verrou.deverrouiller(), isA<DeverrouillageReussi>());
    expect(verrou.state, Verrou.ouvert);
  });

  test('l\'option d\'un autre compte ne s\'applique pas', () async {
    await storage.setBiometrieCompte('0611111111');
    await verrou.preparerDemarrage();
    expect(verrou.state, Verrou.ouvert);
  });

  test('après une connexion par mot de passe, pas de seconde demande',
      () async {
    await storage.setBiometrieCompte('0700000000');
    VerrouBiometriqueNotifier.marquerOuvert();
    await verrou.preparerDemarrage();
    expect(verrou.state, Verrou.ouvert);
  });

  test('retour au premier plan : verrou au-delà du délai de grâce', () async {
    await storage.setBiometrieCompte('0700000000');
    VerrouBiometriqueNotifier.marquerOuvert();
    await verrou.preparerDemarrage();

    verrou.enArrierePlan();
    verrou.auPremierPlan(DateTime.now().add(const Duration(seconds: 5)));
    expect(verrou.state, Verrou.ouvert, reason: 'absence brève (photo…)');

    verrou.enArrierePlan();
    verrou.auPremierPlan(
        DateTime.now().add(VerrouBiometriqueNotifier.delaiDeGrace));
    expect(verrou.state, Verrou.retour);
  });

  test('biométrie retirée de l\'appareil : option coupée, repli', () async {
    await storage.setBiometrieCompte('0700000000');
    await verrou.preparerDemarrage();
    biometrie.dispo = BiometricAvailability.indisponible;

    final issue = await verrou.deverrouiller();
    expect(issue, isA<DeverrouillageRefuse>());
    expect((issue as DeverrouillageRefuse).optionPerdue, isTrue);
    expect(verrou.state, Verrou.demarrage);
    expect(await storage.getBiometrieCompte(), isNull);
  });

  testWidgets('l\'écran de verrou propose le repli par mot de passe',
      (tester) async {
    biometrie.reponse = const BiometricDismissed();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        biometricServiceProvider.overrideWithValue(biometrie),
      ],
      child: const MaterialApp(home: VerrouBiometriquePage()),
    ));
    await tester.pumpAndSettle();

    // L'invite est lancée d'emblée, puis relançable depuis le bouton.
    expect(biometrie.demandes, 1);
    expect(find.text('Application verrouillée'), findsOneWidget);
    expect(find.text('Se connecter avec mon mot de passe'), findsOneWidget);

    await tester.tap(find.text('Déverrouiller avec l\'empreinte digitale'));
    await tester.pumpAndSettle();
    expect(biometrie.demandes, 2);
  });

  group('proposition après connexion', () {
    test('rien à proposer sans connexion par mot de passe', () async {
      expect(await verrou.aProposer(), isNull);
    });

    test('proposée une seule fois par compte', () async {
      VerrouBiometriqueNotifier.marquerConnexion();
      expect(await verrou.aProposer(), isNotNull);
      await verrou.marquerProposee();

      VerrouBiometriqueNotifier.marquerConnexion();
      expect(await verrou.aProposer(), isNull);
    });

    test('pas de proposition si l\'option est déjà active', () async {
      await storage.setBiometrieCompte('0700000000');
      VerrouBiometriqueNotifier.marquerConnexion();
      expect(await verrou.aProposer(), isNull);
    });

    test('pas de proposition sans capteur utilisable', () async {
      biometrie.dispo = BiometricAvailability.indisponible;
      VerrouBiometriqueNotifier.marquerConnexion();
      expect(await verrou.aProposer(), isNull);
    });

    Widget app() => ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(storage),
            biometricServiceProvider.overrideWithValue(biometrie),
          ],
          child: const MaterialApp(
            home: PropositionBiometrie(child: Scaffold(body: Text('Accueil'))),
          ),
        );

    testWidgets('« Activer » valide par l\'OS et active l\'option',
        (tester) async {
      VerrouBiometriqueNotifier.marquerConnexion();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Utiliser l\'empreinte digitale ?'), findsOneWidget);
      await tester.tap(find.text('ACTIVER'));
      await tester.pumpAndSettle();

      expect(biometrie.demandes, 1);
      expect(await storage.getBiometrieCompte(), '0700000000');
      expect(find.text('Déverrouillage biométrique activé.'), findsOneWidget);
    });

    testWidgets('« Plus tard » ne demande rien et ne revient pas',
        (tester) async {
      VerrouBiometriqueNotifier.marquerConnexion();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('PLUS TARD'));
      await tester.pumpAndSettle();

      expect(biometrie.demandes, 0);
      expect(await storage.getBiometrieCompte(), isNull);
      expect(await storage.getBiometrieProposee('0700000000'), isTrue);
    });
  });
}
