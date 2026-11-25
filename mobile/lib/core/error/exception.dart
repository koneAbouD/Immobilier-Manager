import 'package:flutter/foundation.dart';

import '../network/diagnostic_reseau.dart';
import 'failure.dart';

/// Message affiché quand l'erreur n'a rien de lisible à dire (bug, réponse
/// inattendue) : jamais le texte technique de l'exception.
const String kMsgErreurInattendue =
    'Une erreur inattendue s\'est produite. Réessayez ; si le problème '
    'persiste, contactez le support.';

/// Exception dont le [message] est déjà rédigé pour l'écran (localisation
/// refusée, fichier illisible…). Toute erreur « lisible » levée hors de la
/// couche réseau en hérite, pour que [messageErreur] la montre telle quelle.
class ErreurLisible implements Exception {
  final String message;
  const ErreurLisible(this.message);

  @override
  String toString() => message;
}

/// Message à présenter à l'utilisateur pour n'importe quelle erreur capturée
/// (`catch (e)`, `AsyncValue.error`, échec d'un `fold`).
///
/// Ordre : message déjà lisible ([Failure], [ApiException], [NetworkException],
/// [ErreurLisible], ou `String` levée par `throw f.message`) ; sinon
/// [fallback]. Une erreur imprévue (TypeError, FormatException…) n'est jamais
/// montrée brute : elle est journalisée en debug et remplacée par [fallback].
String messageErreur(Object? error, {String fallback = kMsgErreurInattendue}) {
  final message = switch (error) {
    String s => s,
    Failure f => f.message,
    ApiException e => e.message,
    NetworkException e => e.message,
    ErreurLisible e => e.message,
    _ => null,
  };
  if (message != null && message.trim().isNotEmpty) return message.trim();
  debugPrint('Erreur non traduite pour l\'écran : ${error.runtimeType} — $error');
  return fallback;
}

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
