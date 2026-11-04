import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/storage/secure_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';
import 'features/auth/presentation/widgets/auth_ui.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  // L'apparence choisie est lue avant le premier frame : l'application s'ouvre
  // directement dans la bonne couleur, sans flash de l'apparence par défaut.
  final apparence = await ThemeSettings.charger(const SecureStorage());
  runApp(ProviderScope(
    overrides: [themeSettingsInitialProvider.overrideWithValue(apparence)],
    child: const ImmobilierManagerApp(),
  ));
}

/// Clé du navigateur racine : à la déconnexion (volontaire ou subie), la pile
/// est vidée pour revenir à la connexion quelle que soit la profondeur.
final _navigatorKey = GlobalKey<NavigatorState>();

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
        child: child ?? const SizedBox.shrink(),
      ),
      home: switch (authState) {
        AuthInitial() => const _SplashScreen(),
        AuthAuthenticated() => const HomeScreen(),
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
