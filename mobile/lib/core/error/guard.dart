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
  } catch (_) {
    return const Left(UnknownFailure());
  }
}

Failure failureFromApi(ApiException e) => switch (e.statusCode) {
      400 => ValidationFailure(e.message),
      401 => AuthFailure(e.message),
      404 => NotFoundFailure(e.message),
      409 => ConflictFailure(e.message, code: e.code),
      _ => ServerFailure(e.message, statusCode: e.statusCode),
    };
