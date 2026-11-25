import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app/droits_ecriture.dart';
import 'core/app/redemarrage.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/verrou_biometrique_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';
import 'features/auth/presentation/providers/verrou_biometrique.dart';
import 'features/auth/presentation/widgets/auth_ui.dart';
import 'features/auth/presentation/widgets/proposition_biometrie.dart';
import 'features/organisation/presentation/pages/porte_organisation.dart';
import 'features/organisation/presentation/providers/organisation_providers.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  // L'apparence choisie est lue avant le premier frame : l'application s'ouvre
  // directement dans la bonne couleur, sans flash de l'apparence par défaut.
  final apparence = await ThemeSettings.charger(const SecureStorage());
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

  /// Verrou biométrique : départ et retour au premier plan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (ref.read(authNotifierProvider) is! AuthAuthenticated) return;
    final verrou = ref.read(verrouBiometriqueProvider.notifier);
    switch (etat) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        verrou.enArrierePlan();
      case AppLifecycleState.resumed:
        verrou.auPremierPlan();
      // `inactive` n'est pas un départ : la fenêtre Face ID, un appel entrant
      // ou le centre de contrôle le déclenchent sans quitter l'application.
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Sous l'écran de verrou, le bouton retour d'Android ne doit pas dépiler
  /// les pages cachées dessous : il est absorbé.
  @override
  Future<bool> didPopRoute() async =>
      ref.read(verrouBiometriqueProvider) == Verrou.retour;

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
    final verrou = ref.watch(verrouBiometriqueProvider);
    final couvert =
        authState is AuthAuthenticated && verrou == Verrou.retour;

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

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next is AuthUnauthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.popUntil((route) => route.isFirst);
        });
      }
    });

    return MaterialApp(
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
          peutEcrire: authState is AuthAuthenticated ? ref.watch(peutEcrireProvider) : true,
          // Au retour au premier plan, le verrou couvre les pages ouvertes
          // sans les détruire : une fois déverrouillé, on retrouve la page
          // quittée. La pile reste toujours au même rang du Stack, pour que
          // son état survive à l'apparition du verrou.
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Masquées et inertes sous le verrou (lecteurs d'écran compris).
              ExcludeSemantics(
                excluding: couvert,
                child: child ?? const SizedBox.shrink(),
              ),
              if (couvert) const VerrouBiometriquePage(),
            ],
          ),
        ),
      ),
      home: switch (authState) {
        AuthInitial() => const _SplashScreen(),
        // Session retrouvée au lancement : l'accueil attend la biométrie.
        AuthAuthenticated() when verrou == Verrou.demarrage =>
          const VerrouBiometriquePage(),
        // La proposition d'activer la biométrie s'accroche à l'accueil, une
        // fois l'organisation choisie.
        AuthAuthenticated() => const PorteOrganisation(
            child: PropositionBiometrie(child: HomeScreen())),
        _ => const LoginPage(),
      },
    );
  }
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
              AuthBrand(
                assetLogo: 'assets/images/logo_tmk.png',
                compact: true,
                subtitle: '',
              ),
              SizedBox(height: 28),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
}
