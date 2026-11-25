/// Sealed class représentant toutes les erreurs métier de l'application.
/// Utilisée avec `Either<Failure, T>` pour éviter les exceptions non gérées.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Erreur réseau (timeout, pas de connexion)
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion réseau.']);
}

/// Erreur serveur (5xx ou statut non catégorisé)
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

/// Ressource introuvable (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Ressource introuvable.']);
}

/// Erreur d'authentification (401)
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentification échouée.']);
}

/// Données invalides (400), valeur refusée (422) ou fichier trop lourd (413).
class ValidationFailure extends Failure {
  /// Code renvoyé par le backend (ex. `VALIDATION_FAILED`, `FILE_TOO_LARGE`).
  final String? code;
  const ValidationFailure(super.message, {this.code});
}

/// Droits insuffisants (403) : rôle trop faible ou accès à l'organisation
/// retiré. Distinct d'[AuthFailure] : la session reste valable.
class AccesRefuseFailure extends Failure {
  final String? code;
  const AccesRefuseFailure(super.message, {this.code});
}

/// Refus par une règle de gestion ou conflit de données (409).
class ConflictFailure extends Failure {
  /// Code métier stable (ex. `PAIEMENT_DEPASSE_RESTE_DU`).
  final String? code;
  const ConflictFailure(super.message, {this.code});
}

/// Refus lié à l'abonnement (402) : limite de la formule atteinte, essai
/// terminé ou abonnement suspendu.
class AbonnementFailure extends Failure {
  final String? code;
  const AbonnementFailure(super.message, {this.code});
}

/// Erreur inconnue / non catégorisée
class UnknownFailure extends Failure {
  const UnknownFailure(
      [super.message = 'Une erreur inattendue s\'est produite.']);
}
