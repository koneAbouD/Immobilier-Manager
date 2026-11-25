import '../network/diagnostic_reseau.dart';

/// Exception lancée par la couche réseau (datasource).
/// Toujours convertie en [Failure] dans le repository.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  /// Code métier renvoyé par le backend (`error` de l'ApiError), ex.
  /// `APPARTEMENT_DEJA_LOUE`.
  final String? code;
  final Map<String, dynamic>? body;

  const ApiException(this.statusCode, this.message, {this.code, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Exception réseau bas niveau : le serveur n'a pas répondu (timeout, pas de
/// connexion, appel détourné par un portail Wi-Fi).
///
/// [cause] distingue un accès coupé, un internet absent ou un serveur
/// indisponible ; [message] dit déjà à l'utilisateur quoi faire.
class NetworkException implements Exception {
  final String message;
  final CauseIndisponibilite cause;
  const NetworkException([
    this.message = 'Pas de connexion réseau.',
    this.cause = CauseIndisponibilite.inconnue,
  ]);

  @override
  String toString() => message;
}
