import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/cache/reponse_cache.dart';
import '../../../../core/network/etat_reseau.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  final SecureStorage _storage;

  const AuthRepositoryImpl(this._datasource, this._storage);

  @override
  Future<Either<Failure, void>> login(String username, String password) =>
      guard(() async {
        final tokens = await _datasource.login(username, password);
        // Nouvelle session : l'organisation du compte précédent est oubliée.
        if (await _storage.getUsername() != username) await _storage.clearOrganisationId();
        await _storage.saveTokens(
          accessToken: tokens['accessToken'] as String,
          refreshToken: tokens['refreshToken'] as String?,
          expiresInSeconds: (tokens['expiresIn'] as num?)?.toInt(),
        );
        await _storage.saveUsername(username);
      });

  @override
  Future<Either<Failure, void>> inscrire({
    required String organisation,
    required String prenom,
    required String nom,
    String? email,
    required String telephone,
    required String motDePasse,
  }) =>
      guard(() async {
        final tokens = await _datasource.inscrire({
          'organisation': organisation,
          'prenom': prenom,
          'nom': nom,
          'email': ?email,
          'telephone': telephone,
          'motDePasse': motDePasse,
        });
        await _storage.clearOrganisationId();
        await _storage.saveTokens(
          accessToken: tokens['accessToken'] as String,
          refreshToken: tokens['refreshToken'] as String?,
          expiresInSeconds: (tokens['expiresIn'] as num?)?.toInt(),
        );
        // Le téléphone est l'identifiant de connexion.
        await _storage.saveUsername(telephone);
      });

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    // Les tokens locaux partent quoi qu'il arrive : une déconnexion ne doit
    // jamais échouer parce que le serveur est injoignable.
    await _storage.clearTokens();
    // Rien de la session ne survit sur l'appareil : réponses rejouables et
    // bandeau. Sans attendre — la déconnexion ne dépend pas d'un disque lent.
    EtatReseau.instance.joignable();
    unawaited(ReponseCache.instance.vider());
    if (refreshToken != null) {
      try {
        await _datasource.logout(refreshToken);
      } catch (_) {}
    }
  }

  @override
  Future<Either<Failure, void>> rouvrirSession(String refreshToken) =>
      guard(() async {
        await _storage.saveRefreshToken(refreshToken);
        if (!await _datasource.renouveler()) {
          throw const ApiException(
              401, 'Votre session a expiré. Veuillez vous reconnecter.');
        }
      });

  @override
  Future<bool> hasSession() async => (await _storage.getRefreshToken()) != null;

  @override
  Future<String?> currentUsername() => _storage.getUsername();
}
