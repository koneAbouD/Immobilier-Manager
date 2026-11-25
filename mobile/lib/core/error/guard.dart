import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'exception.dart';
import 'failure.dart';

/// Exécute un appel de datasource et convertit toute exception en [Failure].
///
/// Point unique de la traduction exception → échec : chaque repository s'en
/// sert au lieu de répéter le même try/catch dans chaque méthode.
Future<Either<Failure, T>> guard<T>(Future<T> Function() appel) async {
  try {
    return Right(await appel());
  } on ApiException catch (e) {
    return Left(failureFromApi(e));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on ErreurLisible catch (e) {
    return Left(UnknownFailure(e.message));
  } catch (e, pile) {
    // Bug côté application (parsing d'un modèle, null inattendu…) : l'écran
    // affiche un message neutre, mais la cause ne doit pas disparaître.
    debugPrint('guard : erreur inattendue ${e.runtimeType} — $e\n$pile');
    return const Left(UnknownFailure());
  }
}

/// Statut HTTP → famille d'échec. Le message vient toujours du backend
/// (ApiError.message, déjà rédigé pour l'utilisateur) ; le `code` métier est
/// conservé pour que l'écran réagisse sans analyser le texte.
Failure failureFromApi(ApiException e) => switch (e.statusCode) {
      400 || 413 || 422 => ValidationFailure(e.message, code: e.code),
      401 => AuthFailure(e.message),
      402 => AbonnementFailure(e.message, code: e.code),
      403 => AccesRefuseFailure(e.message, code: e.code),
      404 => NotFoundFailure(e.message),
      409 => ConflictFailure(e.message, code: e.code),
      _ => ServerFailure(e.message, statusCode: e.statusCode),
    };
