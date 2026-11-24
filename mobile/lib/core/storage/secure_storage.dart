import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper autour de [FlutterSecureStorage].
/// Point unique d'accès au stockage sécurisé des tokens.
class SecureStorage {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUsername = 'username';
  static const _kThemeAccent = 'theme_accent';
  static const _kThemeMode = 'theme_mode';
  static const _kOrganisationId = 'organisation_id';

  final FlutterSecureStorage _storage;

  const SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> getUsername() => _storage.read(key: _kUsername);

  Future<void> saveTokens({
    required String accessToken,
    required String? refreshToken,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    }
  }

  Future<void> saveUsername(String username) =>
      _storage.write(key: _kUsername, value: username);

  /// Apparence choisie (Réglages › Apparence) : conservée à la déconnexion,
  /// elle appartient à l'appareil et non à la session.
  Future<String?> getThemeAccent() => _storage.read(key: _kThemeAccent);
  Future<String?> getThemeMode() => _storage.read(key: _kThemeMode);

  Future<void> setThemeAccent(String nom) =>
      _storage.write(key: _kThemeAccent, value: nom);

  Future<void> setThemeMode(String nom) =>
      _storage.write(key: _kThemeMode, value: nom);

  /// Organisation dans laquelle on travaille (en-tête `X-Organisation-Id`).
  Future<int?> getOrganisationId() async =>
      int.tryParse(await _storage.read(key: _kOrganisationId) ?? '');

  Future<void> setOrganisationId(int id) =>
      _storage.write(key: _kOrganisationId, value: '$id');

  Future<void> clearOrganisationId() => _storage.delete(key: _kOrganisationId);

  /// Fin de session : jetons et organisation active partent ensemble, pour
  /// que le compte suivant ne démarre jamais dans l'organisation du précédent.
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kOrganisationId);
  }
}
