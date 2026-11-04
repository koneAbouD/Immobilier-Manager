import 'package:fpdart/fpdart.dart';

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
        await _storage.saveTokens(
          accessToken: tokens['accessToken'] as String,
          refreshToken: tokens['refreshToken'] as String?,
        );
        await _storage.saveUsername(username);
      });

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    // Les tokens locaux partent quoi qu'il arrive : une déconnexion ne doit
    // jamais échouer parce que le serveur est injoignable.
    await _storage.clearTokens();
    if (refreshToken != null) {
      try {
        await _datasource.logout(refreshToken);
      } catch (_) {}
    }
  }

  @override
  Future<bool> hasSession() async => (await _storage.getRefreshToken()) != null;

  @override
  Future<String?> currentUsername() => _storage.getUsername();
}
