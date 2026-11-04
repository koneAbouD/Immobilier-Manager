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

/// Données invalides (400)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Refus par une règle de gestion ou conflit de données (409).
class ConflictFailure extends Failure {
  /// Code métier stable (ex. `PAIEMENT_DEPASSE_RESTE_DU`).
  final String? code;
  const ConflictFailure(super.message, {this.code});
}

/// Erreur inconnue / non catégorisée
class UnknownFailure extends Failure {
  const UnknownFailure(
      [super.message = 'Une erreur inattendue s\'est produite.']);
}
