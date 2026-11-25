import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tmk_pin/tmk_pin.dart';

import '../../../../core/app/redemarrage.dart';
import '../../../../core/app/sorties_application.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories_impl/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'unlock_outcome.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDatasource(ref.watch(apiClientProvider)),
    ref.watch(secureStorageProvider),
  ),
);

/// Unique pour tout le processus : la clé du coffre, gardée en mémoire tant
/// que la session est déverrouillée, doit survivre au conteneur Riverpod
/// recréé à chaque ouverture de session et changement d'organisation
/// ([Redemarrage]). Sans elle, ni le rechiffrement des jetons renouvelés ni
/// l'activation de la biométrie ne seraient possibles.
final _pinService = PinService(const PinStore(SecureKeyValueStore()));

/// Verrou local par code d'accès (paquet `tmk_pin`, repris de VTC Manager).
final pinServiceProvider = Provider<PinService>((_) => _pinService);

/// Biométrie de l'appareil : Face ID / Touch ID sur iOS, empreinte ou visage
/// sur Android, rien ailleurs (web) — le code reste alors le seul chemin.
final biometricServiceProvider =
    Provider<BiometricService>((_) => BiometricService());

/// Session, code d'accès et déverrouillage biométrique — sur le modèle de
/// VTC Manager.
///
/// Le code à 5 chiffres ne remplace pas la connexion : il rouvre une session
/// déjà obtenue, dont le refresh token n'existe sur l'appareil, verrouillé,
/// que chiffré par une clé dérivée du code. La biométrie, en option, range
/// cette clé dans le Keychain / Keystore pour ouvrir d'un doigt.
///
/// Parcours :
/// - connexion (ou inscription) → choix du code ([AuthPinSetup]), ou reprise du
///   code existant après une déconnexion volontaire ([AuthPinResume]) ;
/// - lancement à froid avec un code → [AuthLocked] ;
/// - retour au premier plan après [delaiDeGrace] → [AuthLocked], les pages
///   ouvertes restant conservées sous l'écran de code.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final PinService _pin;
  final BiometricService _biometrics;
  final SecureStorage _storage;

  AuthNotifier(
    this._repository, {
    required PinService pin,
    required BiometricService biometrics,
    required SecureStorage storage,
  })  : _pin = pin,
        _biometrics = biometrics,
        _storage = storage,
        super(const AuthInitial());

  /// La session a été ouverte — code choisi, repris ou saisi — par ce
  /// processus. Statique : le conteneur est recréé à l'entrée dans
  /// l'application et à chaque changement d'organisation, sans quoi le
  /// démarrage qui suit redemanderait le code aussitôt saisi.
  static bool _sessionOuverte = false;

  @visibleForTesting
  static void reinitialiserPourTests() => _sessionOuverte = false;

  /// Sortie voulue par l'application (photo de bail, fichier, partage d'une
  /// quittance, WhatsApp, itinéraire, appel — voir [SortiesApplication]) : au-
  /// delà de cette absence, le retour redemande quand même le code, le
  /// téléphone a pu être posé et changer de mains. Toute autre sortie
  /// verrouille aussitôt.
  static const absenceVoulueMax = Duration(minutes: 10);

  /// Au-delà, le déverrouillage rend la main plutôt que de faire patienter
  /// devant un écran figé : l'application s'ouvre en consultation.
  static const _delaiReouverture = Duration(seconds: 8);

  /// Heure du départ pour une sortie voulue, `null` au premier plan.
  DateTime? _depart;

  /// L'écran a commencé à céder la place (inactive) pendant une sortie voulue :
  /// le départ qui suit est le sien, si tard qu'il arrive. Android ne signale
  /// le départ (paused) qu'une fois l'autre application affichée — plusieurs
  /// secondes quand WhatsApp démarre à froid —, le premier signal (inactive)
  /// arrive aussitôt.
  bool _departVoulu = false;

  DateTime Function() _maintenant = DateTime.now;

  @visibleForTesting
  set horloge(DateTime Function() horloge) => _maintenant = horloge;

  /// Invite biométrique de l'OS ouverte : elle fait passer l'application
  /// « inactive », voire en arrière-plan ; ce n'est pas un départ.
  bool _inviteSysteme = false;

  /// Prénom salué sur l'écran de code.
  String? _nom;

  // ── Démarrage, connexion ────────────────────────────────────────────────

  Future<void> bootstrap() async {
    if (state is! AuthInitial) return;
    final session = await _repository.hasSession();

    // Conteneur recréé (entrée dans l'application, changement
    // d'organisation) : la session vient d'être ouverte par ce processus.
    if (_sessionOuverte && session) {
      state = AuthAuthenticated(await _nomCourant() ?? '');
      return;
    }

    final codeConfigure = await _pin.isConfigured();
    // Un code configuré prime : seul le coffre chiffré fait foi, les jetons en
    // clair d'une session laissée ouverte sont effacés. Sauf après une
    // déconnexion volontaire : le refresh token du coffre est révoqué.
    if (codeConfigure && !await _storage.isLoggedOut()) {
      _pin.lock();
      await _storage.clearSessionTokens();
      _nom = await _pin.displayName();
      state = AuthLocked(displayName: _nom);
      return;
    }

    if (session) {
      // Session ouverte sans code utilisable : appareil connecté avant que le
      // code n'existe, ou application fermée pendant le choix (ou la reprise)
      // du code. On règle la question du code avant d'ouvrir l'application.
      final nom = await _nomCourant();
      state = codeConfigure
          ? AuthPinResume(displayName: nom)
          : AuthPinSetup(displayName: nom);
      return;
    }
    state = const AuthUnauthenticated();
  }

  /// Connexion par téléphone et mot de passe, puis choix ou reprise du code :
  /// le code d'accès est le seul chemin d'entrée dans l'application.
  Future<void> login(String username, String password) async {
    state = const AuthLoading();
    final result = await _repository.login(username.trim(), password);
    await result.fold(
      (failure) async => state = AuthError(failure.message),
      (_) => _apresConnexion(),
    );
  }

  /// Renvoie le message d'échec, ou null si l'inscription a réussi (le choix
  /// du code suit).
  Future<String?> inscrire({
    required String organisation,
    required String prenom,
    required String nom,
    String? email,
    required String telephone,
    required String motDePasse,
  }) async {
    final result = await _repository.inscrire(
      organisation: organisation.trim(),
      prenom: prenom.trim(),
      nom: nom.trim(),
      email: email == null || email.trim().isEmpty
          ? null
          : email.trim().toLowerCase(),
      telephone: telephone.trim(),
      motDePasse: motDePasse,
    );
    return result.fold((failure) => failure.message, (_) async {
      await _apresConnexion();
      return null;
    });
  }

  Future<void> _apresConnexion() async {
    // Un code rattaché à un autre compte n'a rien à faire ici.
    await _pin.resetIfOtherAccount(await _compte());
    final nom = await _nomCourant();
    state = await _pin.isConfigured()
        ? AuthPinResume(displayName: nom)
        : AuthPinSetup(displayName: nom);
  }

  /// Entrée dans l'application après le choix ou la reprise du code : sur un
  /// conteneur neuf, rien de la session précédente (autre compte, autre
  /// organisation) ne reste en cache.
  Future<void> _entrer() async {
    _sessionOuverte = true;
    if (Redemarrage.enregistre) {
      await Redemarrage.lancer();
    } else {
      state = AuthAuthenticated(_nom ?? '');
    }
  }

  /// Prénom lu dans le jeton courant (jamais un numéro de téléphone).
  Future<String?> _nomCourant() async => _nom =
      DisplayName.resolve(accessToken: await _storage.getAccessToken());

  /// Compte auquel rattacher le code : l'identifiant normalisé par Keycloak,
  /// à défaut celui saisi.
  Future<String> _compte() async {
    final claims = JwtClaims.parse(await _storage.getAccessToken());
    return claims.preferredUsername ?? await _storage.getUsername() ?? '';
  }

  // ── Code d'accès ────────────────────────────────────────────────────────

  /// Installe le code. Retourne un message d'erreur, `null` si tout va bien.
  ///
  /// [entrerDansLApplication] : faux depuis les réglages (session déjà
  /// ouverte), vrai à la suite d'une connexion.
  Future<String?> configurePin(
    String code, {
    bool entrerDansLApplication = true,
  }) async {
    final invalide = PinService.validate(code);
    if (invalide != null) return invalide;

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return 'Session introuvable. Reconnectez-vous pour définir un code.';
    }
    await _pin.configure(
      code: code,
      refreshToken: refreshToken,
      account: await _compte(),
      displayName: await _nomCourant(),
    );
    await _storage.setLoggedOut(false);
    if (entrerDansLApplication) await _entrer();
    return null;
  }

  /// Reprise du code existant après une reconnexion ([AuthPinResume]) : la
  /// saisie re-dérive la clé du coffre, dont l'ancien refresh token — révoqué
  /// par la déconnexion — est aussitôt remplacé par le neuf.
  Future<UnlockOutcome> resumePin(String code) async {
    final nom = state is AuthPinResume
        ? (state as AuthPinResume).displayName
        : null;
    switch (await _pin.unlock(code)) {
      case UnlockFailure(:final remainingAttempts):
        return UnlockWrong(remainingAttempts);
      case UnlockThrottled(:final remaining):
        return UnlockWait(remaining);
      case UnlockExhausted():
        // Coffre perdu, mais la session vient d'être ouverte : on enchaîne
        // sur le choix d'un nouveau code.
        state = AuthPinSetup(displayName: nom);
        return const UnlockRequiresLogin();
      case UnlockSuccess():
        await _synchroniserCoffre();
        await _storage.setLoggedOut(false);
        await _entrer();
        return const UnlockOk();
    }
  }

  /// « Code oublié ? » depuis la reprise : la session restant ouverte, on
  /// passe au choix d'un nouveau code sans redemander le mot de passe.
  Future<void> restartPinSetup() async {
    final nom = state is AuthPinResume
        ? (state as AuthPinResume).displayName
        : null;
    await _pin.reset();
    state = AuthPinSetup(displayName: nom);
  }

  /// Change le code depuis les réglages. Message d'erreur, ou `null`.
  Future<String?> changePin({
    required String currentCode,
    required String newCode,
  }) async {
    final invalide = PinService.validate(newCode);
    if (invalide != null) return invalide;
    final change =
        await _pin.changeCode(currentCode: currentCode, newCode: newCode);
    return change ? null : 'Code actuel incorrect.';
  }

  Future<bool> isPinConfigured() => _pin.isConfigured();

  // ── Verrouillage ────────────────────────────────────────────────────────

  /// Remet la session sous clé : les jetons en clair sont effacés, seul le
  /// coffre chiffré subsiste. Immédiat — l'écran de code couvre l'application
  /// dès la frame suivante —, l'effacement suit.
  Future<void> lock({String? message}) async {
    if (state is! AuthAuthenticated) return;
    _depart = null;
    _departVoulu = false;
    _pin.lock();
    state = AuthLocked(displayName: _nom, message: message);
    await _storage.clearSessionTokens();
  }

  /// L'écran cède la place (volet de notifications, centre de contrôle,
  /// invite système, début d'un départ) : rien à verrouiller, sauf à retenir
  /// qu'une sortie voulue commence.
  void inactive() {
    if (state is AuthAuthenticated && SortiesApplication.instance.voulue) {
      _departVoulu = true;
    }
  }

  /// L'application passe en arrière-plan : verrouillage immédiat, avant même
  /// le retour — l'aperçu du sélecteur d'applications et le retour montrent
  /// l'écran de code, jamais les données. Seule une sortie voulue y échappe.
  Future<void> enArrierePlan() async {
    // Invite biométrique, ou hidden puis paused d'une même sortie : déjà
    // traité.
    if (_inviteSysteme || state is! AuthAuthenticated || _depart != null) {
      return;
    }
    final voulue = SortiesApplication.instance.voulue || _departVoulu;
    _departVoulu = false;
    if (voulue) {
      _depart = _maintenant();
      return;
    }
    await lock();
  }

  /// Retour au premier plan : une sortie voulue trop longue verrouille.
  Future<void> auPremierPlan() async {
    _departVoulu = false;
    final depart = _depart;
    _depart = null;
    if (depart == null || state is! AuthAuthenticated) return;
    if (_maintenant().difference(depart) > absenceVoulueMax) await lock();
  }

  /// Vérifie le code saisi et, s'il est bon, rouvre la session.
  Future<UnlockOutcome> unlock(String code) async =>
      _traiterDeverrouillage(await _pin.unlock(code));

  /// Déverrouille par la biométrie, quand l'option est active.
  ///
  /// Un refus de l'OS ne coûte aucun essai du code ; la temporisation du code,
  /// elle, reste opposable — sans quoi la biométrie la contournerait.
  /// [onAccepted] marque la fin de l'invite système et le début du travail
  /// réel (déchiffrement, réouverture de session).
  Future<UnlockOutcome> unlockWithBiometrics(
      {void Function()? onAccepted}) async {
    final throttle = await _pin.throttleRemaining();
    if (throttle != null) return UnlockWait(throttle);

    final dispo = await _biometrics.availability();
    if (!dispo.disponible) {
      // Plus rien d'enrôlé depuis l'activation : on abandonne l'option.
      await _pin.disableBiometrics();
      return UnlockBiometricsFailed(dispo.raison);
    }

    final autorisation = await _inviter(
        'Confirmez votre identité pour rouvrir l\'application.');
    switch (autorisation) {
      case BiometricDismissed():
        return const UnlockBiometricsFailed();
      case BiometricUnavailable(:final message, :final definitif):
        if (definitif) await _pin.disableBiometrics();
        return UnlockBiometricsFailed(message);
      case BiometricAccepted():
        onAccepted?.call();
        final result = await _pin.unlockWithBiometrics();
        if (result == null) {
          return const UnlockBiometricsFailed(
            'Le déverrouillage biométrique a été réinitialisé. '
            'Saisissez votre code.',
          );
        }
        return _traiterDeverrouillage(result);
    }
  }

  Future<BiometricOutcome> _inviter(String raison) async {
    _inviteSysteme = true;
    try {
      return await _biometrics.authenticate(raison: raison);
    } finally {
      _inviteSysteme = false;
      _depart = null;
    }
  }

  /// Suite commune aux deux chemins : le coffre a rendu (ou non) le refresh
  /// token, il reste à rouvrir la session côté serveur.
  Future<UnlockOutcome> _traiterDeverrouillage(UnlockResult result) async {
    switch (result) {
      case UnlockFailure(:final remainingAttempts):
        return UnlockWrong(remainingAttempts);

      case UnlockThrottled(:final remaining):
        return UnlockWait(remaining);

      case UnlockExhausted():
        // Le service a purgé le coffre : connexion complète.
        await _repository.logout();
        state = const AuthUnauthenticated(
            'Code incorrect à plusieurs reprises. Reconnectez-vous.');
        return const UnlockRequiresLogin();

      case UnlockSuccess(:final refreshToken):
        final enCours = _repository.rouvrirSession(refreshToken);
        final rouverte = await enCours.timeout(
          _delaiReouverture,
          onTimeout: () => const Left(NetworkFailure(
              'Le serveur met trop de temps à répondre.')),
        );
        return rouverte.fold<Future<UnlockOutcome>>(
          (failure) async {
            if (_serveurHorsDAtteinte(failure)) {
              // Le code a prouvé l'identité sans le serveur : l'application
              // s'ouvre en consultation (réponses du cache, bandeau). Un
              // renouvellement tardif rechiffrera le coffre.
              unawaited(enCours.then((tardif) async {
                if (tardif.isRight()) await _synchroniserCoffre();
              }));
              _ouvrir();
              return const UnlockOk();
            }
            // Session révoquée côté serveur : le code reste celui de
            // l'utilisateur. Le coffre est gardé, la reconnexion le
            // redemandera ([AuthPinResume]).
            _pin.lock();
            await _storage.setLoggedOut(true);
            await _repository.logout();
            state = const AuthUnauthenticated(
                'Votre session a expiré. Veuillez vous reconnecter.');
            return const UnlockRequiresLogin();
          },
          (_) async {
            unawaited(_synchroniserCoffre());
            _ouvrir();
            return const UnlockOk();
          },
        );
    }
  }

  static bool _serveurHorsDAtteinte(Failure f) => switch (f) {
        NetworkFailure() => true,
        ServerFailure(:final statusCode) => (statusCode ?? 500) >= 500,
        _ => false,
      };

  void _ouvrir() {
    _sessionOuverte = true;
    _depart = null;
    state = AuthAuthenticated(_nom ?? '');
  }

  /// Le jeton renouvelé remplace celui du coffre.
  Future<void> _synchroniserCoffre() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _pin.updateRefreshToken(refreshToken);
    }
  }

  // ── Déverrouillage biométrique ──────────────────────────────────────────

  /// Ce que l'appareil sait faire (système, matériel, enrôlement).
  Future<BiometricAvailability> biometricAvailability() =>
      _biometrics.availability();

  Future<bool> isBiometricsEnabled() => _pin.isBiometricsEnabled();

  /// Faut-il proposer l'activation ? Une seule fois, sur un appareil
  /// compatible, quand l'option n'est pas déjà en place.
  Future<BiometricAvailability?> biometricsToPropose() async {
    if (await _pin.hasProposedBiometrics()) return null;
    if (await _pin.isBiometricsEnabled()) return null;
    if (!_pin.isUnlocked) return null;
    final dispo = await _biometrics.availability();
    return dispo.disponible ? dispo : null;
  }

  Future<void> markBiometricsProposed() => _pin.markBiometricsProposed();

  /// Active l'option après une validation biométrique de l'OS. Retourne un
  /// message d'erreur, ou `null` si c'est en place.
  Future<String?> enableBiometrics() async {
    final dispo = await _biometrics.availability();
    if (!dispo.disponible) {
      return dispo.raison ??
          'Le déverrouillage biométrique n\'est pas disponible sur cet '
              'appareil.';
    }
    final autorisation = await _inviter(
        'Confirmez votre identité pour activer ${dispo.libelleAvecArticle}.');
    switch (autorisation) {
      case BiometricDismissed():
        return 'Activation annulée.';
      case BiometricUnavailable(:final message):
        return message;
      case BiometricAccepted():
        final ok = await _pin.enableBiometrics();
        return ok
            ? null
            : 'Session verrouillée. Saisissez votre code, puis réessayez.';
    }
  }

  Future<void> disableBiometrics() => _pin.disableBiometrics();

  // ── Fin de session ──────────────────────────────────────────────────────

  /// Déconnexion volontaire : le code survit (la prochaine connexion le
  /// redemandera), la session et les données consultées, non.
  Future<void> logout() async {
    _pin.lock();
    _sessionOuverte = false;
    await _storage.setLoggedOut(true);
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// « Code oublié ? » depuis l'écran de code : le code est effacé, retour
  /// à la connexion complète.
  Future<void> forgetPin() async {
    await _pin.reset();
    _sessionOuverte = false;
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Le refresh token a été refusé : la session est perdue, le code gardé.
  Future<void> sessionExpiree() async {
    if (state is! AuthAuthenticated) return;
    _pin.lock();
    _sessionOuverte = false;
    await _storage.setLoggedOut(true);
    await _repository.logout();
    state = const AuthUnauthenticated(
        'Session expirée, veuillez vous reconnecter.');
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final pin = ref.watch(pinServiceProvider);
  final notifier = AuthNotifier(
    ref.watch(authRepositoryProvider),
    pin: pin,
    biometrics: ref.watch(biometricServiceProvider),
    storage: ref.watch(secureStorageProvider),
  );
  final client = ref.watch(apiClientProvider)
    ..onSessionExpired = notifier.sessionExpiree
    // Chaque renouvellement rechiffre le coffre, tant que la session est
    // déverrouillée (sinon l'appel est ignoré).
    ..onTokensRenewed = (jeton) => unawaited(pin.updateRefreshToken(jeton));
  ref.onDispose(() => client.onTokensRenewed = null);
  return notifier;
});
