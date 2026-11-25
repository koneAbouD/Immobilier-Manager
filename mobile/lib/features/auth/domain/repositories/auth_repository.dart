import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, void>> login(String username, String password);

  /// Crée l'organisation (essai gratuit) et son propriétaire, puis ouvre la
  /// session. Le téléphone sert d'identifiant ; l'e-mail est facultatif.
  Future<Either<Failure, void>> inscrire({
    required String organisation,
    required String prenom,
    required String nom,
    String? email,
    required String telephone,
    required String motDePasse,
  });

  Future<void> logout();

  /// Rouvre la session à partir du refresh token sorti du coffre du code
  /// d'accès. [NetworkFailure] : serveur hors d'atteinte, la session pourra
  /// reprendre plus tard ; [AuthFailure] : session révoquée.
  Future<Either<Failure, void>> rouvrirSession(String refreshToken);

  /// Vrai si une session (refresh token) est enregistrée sur l'appareil.
  Future<bool> hasSession();

  Future<String?> currentUsername();
}
