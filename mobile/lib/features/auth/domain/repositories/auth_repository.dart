import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, void>> login(String username, String password);

  Future<void> logout();

  /// Vrai si une session (refresh token) est enregistrée sur l'appareil.
  Future<bool> hasSession();

  Future<String?> currentUsername();
}
