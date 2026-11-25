import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tmk_pin/tmk_pin.dart';

import 'core/app/droits_ecriture.dart';
import 'core/app/redemarrage.dart';
import 'core/network/etat_reseau.dart';
import 'core/network/prechargement.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/bandeau_hors_ligne.dart';
import 'core/widgets/prechargement_periodique.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/pin_brand.dart';
import 'features/auth/presentation/pages/pin_lock_page.dart';
import 'features/auth/presentation/pages/pin_resume_page.dart';
import 'features/auth/presentation/pages/pin_setup_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';
import 'features/auth/presentation/widgets/biometric_proposal.dart';
import 'features/organisation/presentation/pages/porte_organisation.dart';
import 'features/organisation/presentation/providers/organisation_providers.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  // L'apparence choisie est lue avant le premier frame : l'application s'ouvre
  // directement dans la bonne couleur, sans flash de l'apparence par défaut.
  final apparence = await ThemeSettings.charger(const SecureStorage());
  // Mode avion, Wi-Fi ou données coupés : le bandeau le dit aussitôt, sans
  // attendre qu'un appel au serveur échoue.
  EtatReseau.instance.suivreAccesReseau();
  runApp(RacineApplication(apparence: apparence));
}

/// Racine : porte le conteneur Riverpod, recréé à neuf par [Redemarrage]
/// (ouverture de session, changement d'organisation).
class RacineApplication extends StatefulWidget {
  final ThemeSettings apparence;

  const RacineApplication({super.key, required this.apparence});

  @override
  State<RacineApplication> createState() => _RacineApplicationState();
}

class _RacineApplicationState extends State<RacineApplication> {
  Key _conteneur = UniqueKey();
  late ThemeSettings _apparence = widget.apparence;

  @override
  void initState() {
    super.initState();
    Redemarrage.enregistrer(() async {
      // L'apparence a pu changer depuis le démarrage : on la relit.
      final apparence = await ThemeSettings.charger(const SecureStorage());
      if (!mounted) return;
      setState(() {
        _apparence = apparence;
        _conteneur = UniqueKey();
      });
    });
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
        key: _conteneur,
        overrides: [themeSettingsInitialProvider.overrideWithValue(_apparence)],
        child: const ImmobilierManagerApp(),
      );
}

class ImmobilierManagerApp extends ConsumerStatefulWidget {
  const ImmobilierManagerApp({super.key});

  @override
  ConsumerState<ImmobilierManagerApp> createState() =>
      _ImmobilierManagerAppState();
}

class _ImmobilierManagerAppState extends ConsumerState<ImmobilierManagerApp>
    with WidgetsBindingObserver {
  /// Faux tant que la première construction n'a pas eu lieu : la palette de
  /// départ n'appelle aucune reconstruction, elle est déjà celle qu'on voit.
  bool _construit = false;

  /// Clé du navigateur racine : à la déconnexion (volontaire ou subie), la pile
  /// est vidée pour revenir à la connexion quelle que soit la profondeur.
  ///
  /// Propre à chaque instance : au redémarrage (conteneur neuf), une clé
  /// globale partagée ferait reprendre l'ancien navigateur — et ses pages liées
  /// à l'ancien conteneur — au lieu d'en bâtir un neuf.
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// En mode « Système », l'apparence suit celle de l'appareil, y compris
  /// quand elle bascule application ouverte.
  @override
  void didChangePlatformBrightness() {
    if (ref.read(themeControllerProvider).mode == ThemeMode.system) {
      setState(() {});
    }
  }

  /// Sous l'écran de code ou session fermée, rien à lire d'avance (plus de
  /// jeton).
  Future<void> _prechargerEcransCles() async {
    if (ref.read(authNotifierProvider) is! AuthAuthenticated) return;
    await prechargerEcransCles(ref);
  }

  /// Code d'accès : départ et retour au premier plan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    final auth = ref.read(authNotifierProvider.notifier);
    switch (etat) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        auth.enArrierePlan();
      case AppLifecycleState.resumed:
        // Retour au premier plan : verrou si l'absence a duré, sinon
        // renouvellement forcé de la session (comme VTC Manager).
        unawaited(auth.auPremierPlan().then((_) {
          if (mounted && ref.read(authNotifierProvider) is AuthAuthenticated) {
            return ref.read(apiClientProvider).renouvelerMaintenant();
          }
        }));
      // `inactive` n'est pas un départ : la fenêtre Face ID, un appel entrant
      // ou le centre de contrôle le déclenchent sans quitter l'application.
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Brightness _luminosite(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
      };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final apparence = ref.watch(themeControllerProvider);

    // La palette est installée ici, avant que le moindre descendant ne se
    // construise : les widgets lisent AppColors au fil de leur `build`. Ceux
    // déjà affichés ne se reconstruiraient pas d'eux-mêmes : on rejoue donc
    // toute la construction une fois le frame passé.
    final changee =
        AppColors.appliquer(apparence.accent, _luminosite(apparence.mode));
    if (changee && _construit) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => WidgetsBinding.instance.reassembleApplication());
    }
    _construit = true;

    // Déconnexion, ou passage au choix (à la reprise) du code après une
    // connexion ou une inscription : les pages empilées — l'inscription
    // notamment — laissent la place à la page d'accès.
    // Renouvellement proactif du jeton d'accès, tant que la session est
    // ouverte : sous l'écran de code, plus aucun jeton en clair.
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      final client = ref.read(apiClientProvider);
      next is AuthAuthenticated
          ? client.demarrerRenouvellement()
          : client.arreterRenouvellement();
    });

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next is AuthUnauthenticated ||
          next is AuthPinSetup ||
          next is AuthPinResume) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.popUntil((route) => route.isFirst);
        });
      }
    });

    // Verrouillée puis rouverte dans les dix minutes, l'application revient
    // sur la page quittée ; au-delà, ou à la déconnexion, la pile est vidée.
    // Au-dessus du MaterialApp : le retour arrière sous l'écran de code est
    // intercepté avant que le navigateur ne dépile la page cachée.
    return ConservationSousVerrou(
      etat: _etatSession(authState),
      navigatorKey: _navigatorKey,
      builder: (context, conservation) => MaterialApp(
        title: 'Immobilier Manager',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
        locale: const Locale('fr', 'FR'),
        theme: AppTheme.clair(apparence.accent),
        darkTheme: AppTheme.sombre(apparence.accent),
        themeMode: apparence.mode,
        // Les couleurs viennent d'AppColors, pas du thème : l'animation de
        // transition mêlerait l'ancien et le nouveau jeu pendant 200 ms.
        themeAnimationDuration: Duration.zero,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: (AppColors.estSombre
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
          // Au-dessus du navigateur : toutes les pages voient les droits.
          child: DroitsEcriture(
            peutEcrire: authState is AuthAuthenticated
                ? ref.watch(peutEcrireProvider)
                : true,
            // Serveur hors d'atteinte : un bandeau dit pourquoi (accès
            // coupé, internet absent, serveur en panne) et quoi faire.
            child: BandeauHorsLigne(
              // Au retour au premier plan, l'écran de code couvre les pages
              // ouvertes sans les détruire.
              child: CouvertureVerrou(
                conservation: conservation,
                ecranVerrou: const PinLockPage(),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        home: switch (authState) {
          AuthInitial() => const _SplashScreen(),
          AuthAuthenticated() => _accueil(conservation),
          // Les écrans ouverts restent construits sous l'écran de code.
          AuthLocked() when conservation.couverte => _accueil(conservation),
          AuthLocked() => const PinLockPage(),
          AuthPinSetup(:final displayName) =>
            PinSetupPage(displayName: displayName),
          AuthPinResume(:final displayName) =>
            PinResumePage(displayName: displayName),
          _ => const LoginPage(),
        },
      ),
    );
  }

  /// Une fois l'organisation choisie, l'accueil porte la proposition
  /// d'activer la biométrie, et lit d'avance les écrans clés pour qu'ils
  /// soient servis hors connexion.
  Widget _accueil(Conservation conservation) => PorteOrganisation(
        key: conservation.cleAccueil,
        child: PrechargementPeriodique(
          precharger: _prechargerEcransCles,
          child: const BiometricProposal(child: HomeScreen()),
        ),
      );

  static EtatSession _etatSession(AuthState state) => switch (state) {
        AuthAuthenticated() => EtatSession.ouverte,
        AuthLocked() => EtatSession.verrouillee,
        AuthUnauthenticated() => EtatSession.fermee,
        _ => EtatSession.transitoire,
      };
}

/// Affiché pendant la vérification de session au démarrage.
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Même logo, aux angles adoucis, que les écrans de code.
              PinBrand(height: 120),
              SizedBox(height: 28),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
}
