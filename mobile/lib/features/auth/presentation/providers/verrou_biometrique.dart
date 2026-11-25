import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/storage/secure_storage.dart';

/// Biométrie de l'appareil (Face ID, Touch ID, empreinte…).
final biometricServiceProvider =
    Provider<BiometricService>((_) => BiometricService());

/// État du verrou biométrique de l'application.
enum Verrou {
  /// Rien à demander : l'application est utilisable.
  ouvert,

  /// Session retrouvée au lancement : l'accueil n'est pas construit tant que
  /// l'utilisateur ne s'est pas identifié (aucun appel réseau, rien à l'écran).
  demarrage,

  /// Retour au premier plan : l'écran de verrou couvre les pages ouvertes,
  /// qui restent construites dessous et réapparaissent telles quelles.
  retour,
}

/// Issue d'une tentative de déverrouillage, pour l'écran de verrou.
sealed class IssueDeverrouillage {
  const IssueDeverrouillage();
}

/// Reconnu : le verrou est levé.
class DeverrouillageReussi extends IssueDeverrouillage {
  const DeverrouillageReussi();
}

/// Rien d'ouvert. [message] est affichable (`null` : simple renoncement).
/// [optionPerdue] : la biométrie ne peut plus servir (plus rien d'enrôlé…),
/// l'option vient d'être coupée — seul reste le repli par mot de passe.
class DeverrouillageRefuse extends IssueDeverrouillage {
  final String? message;
  final bool optionPerdue;

  const DeverrouillageRefuse({this.message, this.optionPerdue = false});
}

/// Verrou d'application par biométrie, sur le modèle de VTC Manager.
///
/// Immobilier Manager n'a pas de code d'accès : la biométrie garde l'entrée
/// d'une session déjà ouverte (jetons Keycloak dans le Keychain / Keystore),
/// et son repli est la connexion classique par téléphone et mot de passe.
///
/// Le verrou est demandé au lancement, quand une session est retrouvée, et au
/// retour au premier plan après une absence d'au moins [delaiDeGrace].
class VerrouBiometriqueNotifier extends StateNotifier<Verrou> {
  /// Absence en deçà de laquelle le retour n'est pas verrouillé : prendre une
  /// photo de bail, choisir un fichier ou partager une quittance fait passer
  /// l'application en arrière-plan quelques secondes, sans que l'utilisateur
  /// l'ait quittée pour autant.
  static const delaiDeGrace = Duration(seconds: 30);

  /// Une session a déjà été ouverte ou déverrouillée par ce processus.
  ///
  /// Statique : le conteneur Riverpod est recréé à chaque ouverture de session
  /// et changement d'organisation ([Redemarrage]) ; sans cela, la connexion
  /// par mot de passe serait aussitôt suivie d'une demande biométrique.
  static bool _ouvertDansCeProcessus = false;

  /// À appeler quand une session vient d'être ouverte par mot de passe ou
  /// inscription : l'identité est prouvée, inutile de la redemander.
  static void marquerOuvert() => _ouvertDansCeProcessus = true;

  /// Une connexion par mot de passe (ou une inscription) vient d'aboutir : la
  /// session est ouverte, et l'accueil pourra proposer d'activer la biométrie.
  /// Statique pour la même raison que [_ouvertDansCeProcessus].
  static bool _propositionEnAttente = false;

  static void marquerConnexion() {
    _ouvertDansCeProcessus = true;
    _propositionEnAttente = true;
  }

  /// Réservé aux tests : remet le processus dans l'état d'un lancement à froid.
  static void reinitialiserPourTests() {
    _ouvertDansCeProcessus = false;
    _propositionEnAttente = false;
  }

  final SecureStorage _storage;
  final BiometricService _biometrie;

  /// L'option est-elle active pour le compte connecté ? Tenue en mémoire pour
  /// verrouiller dès le retour au premier plan, sans lecture asynchrone qui
  /// laisserait entrevoir les pages.
  bool _actif = false;

  /// Invite système ouverte : la fenêtre biométrique fait passer l'application
  /// « inactive », voire en arrière-plan ; ce n'est pas un départ.
  bool _inviteOuverte = false;

  /// Instant du passage en arrière-plan, `null` au premier plan.
  DateTime? _depart;

  VerrouBiometriqueNotifier(this._storage, this._biometrie)
      : super(Verrou.ouvert);

  bool get actif => _actif;

  Future<bool> _lireActif() async {
    final compte = await _storage.getBiometrieCompte();
    return compte != null && compte == await _storage.getUsername();
  }

  /// Au lancement, une session vient d'être retrouvée : verrouille si l'option
  /// est active et que ce processus n'a pas déjà ouvert la session.
  Future<void> preparerDemarrage() async {
    _actif = await _lireActif();
    if (_actif && !_ouvertDansCeProcessus) {
      state = Verrou.demarrage;
    } else {
      _ouvertDansCeProcessus = true;
    }
  }

  /// L'application passe en arrière-plan.
  void enArrierePlan() {
    if (_inviteOuverte || state != Verrou.ouvert) return;
    _depart ??= DateTime.now();
  }

  /// L'application revient au premier plan ; [maintenant] pour les tests.
  void auPremierPlan([DateTime? maintenant]) {
    final depart = _depart;
    _depart = null;
    if (depart == null || !_actif || state != Verrou.ouvert) return;
    if ((maintenant ?? DateTime.now()).difference(depart) >= delaiDeGrace) {
      state = Verrou.retour;
    }
  }

  /// Demande la biométrie à l'OS et lève le verrou si elle aboutit.
  Future<IssueDeverrouillage> deverrouiller() async {
    if (_inviteOuverte) return const DeverrouillageRefuse();

    final dispo = await _biometrie.availability();
    if (!dispo.disponible) {
      // Empreinte ou visage retiré depuis l'activation : l'option ne peut plus
      // servir, la proposer à chaque ouverture serait vain.
      await desactiver();
      return DeverrouillageRefuse(
        message: dispo.raison ??
            'Le déverrouillage biométrique n\'est plus disponible sur cet '
                'appareil. Connectez-vous avec votre mot de passe.',
        optionPerdue: true,
      );
    }

    _inviteOuverte = true;
    final BiometricOutcome issue;
    try {
      issue = await _biometrie.authenticate(
        raison: 'Confirmez votre identité pour ouvrir Immobilier Manager.',
      );
    } finally {
      _inviteOuverte = false;
    }

    switch (issue) {
      case BiometricAccepted():
        _ouvertDansCeProcessus = true;
        _depart = null;
        state = Verrou.ouvert;
        return const DeverrouillageReussi();
      case BiometricDismissed():
        return const DeverrouillageRefuse();
      case BiometricUnavailable(:final message, :final definitif):
        if (definitif) await desactiver();
        return DeverrouillageRefuse(message: message, optionPerdue: definitif);
    }
  }

  /// Repli vers la connexion classique : le verrou s'efface devant la page de
  /// connexion (l'appelant ferme la session).
  void abandonner() {
    _depart = null;
    state = Verrou.ouvert;
  }

  // ── Proposition après connexion ──────────────────────────────────────────

  /// Ce qu'il faut proposer à l'accueil, ou `null` s'il n'y a rien à proposer.
  ///
  /// Une seule fois, juste après une connexion par mot de passe, sur un
  /// appareil compatible, à un compte qui n'a pas l'option et à qui on ne l'a
  /// encore jamais proposée. Consomme l'attente : la question ne revient pas
  /// au prochain affichage de l'accueil (changement d'organisation…).
  Future<BiometricAvailability?> aProposer() async {
    if (!_propositionEnAttente) return null;
    _propositionEnAttente = false;

    final compte = await _storage.getUsername();
    if (compte == null || compte.isEmpty) return null;
    if (await estActif()) return null;
    if (await _storage.getBiometrieProposee(compte)) return null;

    final dispo = await _biometrie.availability();
    return dispo.disponible ? dispo : null;
  }

  /// Mémorise la proposition, acceptée ou non : on ne la refait plus.
  Future<void> marquerProposee() async {
    final compte = await _storage.getUsername();
    if (compte != null && compte.isNotEmpty) {
      await _storage.setBiometrieProposee(compte);
    }
  }

  // ── Réglage ──────────────────────────────────────────────────────────────

  Future<BiometricAvailability> disponibilite() => _biometrie.availability();

  Future<bool> estActif() async => _actif = await _lireActif();

  /// Active l'option après une validation biométrique de l'OS : on ne range
  /// rien pour quelqu'un qui ne saurait pas s'en servir. Renvoie le message
  /// d'échec, ou `null` si l'option est active.
  Future<String?> activer() async {
    final dispo = await _biometrie.availability();
    if (!dispo.disponible) {
      return dispo.raison ??
          'Le déverrouillage biométrique n\'est pas disponible sur cet '
              'appareil.';
    }
    final compte = await _storage.getUsername();
    if (compte == null || compte.isEmpty) {
      return 'Aucune session ouverte sur cet appareil.';
    }

    _inviteOuverte = true;
    final BiometricOutcome issue;
    try {
      issue = await _biometrie.authenticate(
        raison: 'Confirmez votre identité pour activer le déverrouillage '
            'biométrique.',
      );
    } finally {
      _inviteOuverte = false;
      // La fenêtre système a pu passer l'application en arrière-plan.
      _depart = null;
    }

    switch (issue) {
      case BiometricAccepted():
        await _storage.setBiometrieCompte(compte);
        _actif = true;
        return null;
      case BiometricDismissed():
        return 'Activation annulée.';
      case BiometricUnavailable(:final message):
        return message;
    }
  }

  Future<void> desactiver() async {
    await _storage.setBiometrieCompte(null);
    _actif = false;
  }
}

final verrouBiometriqueProvider =
    StateNotifierProvider<VerrouBiometriqueNotifier, Verrou>(
  (ref) => VerrouBiometriqueNotifier(
    ref.watch(secureStorageProvider),
    ref.watch(biometricServiceProvider),
  ),
);
