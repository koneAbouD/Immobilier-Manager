import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper autour de [FlutterSecureStorage].
/// Point unique d'accès au stockage sécurisé des tokens.
class SecureStorage {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kAccessExpiry = 'access_token_expiry'; // epoch ms
  static const _kUsername = 'username';
  static const _kThemeAccent = 'theme_accent';
  static const _kThemeMode = 'theme_mode';
  static const _kOrganisationId = 'organisation_id';
  static const _kDeconnecte = 'deconnecte';

  final FlutterSecureStorage _storage;

  const SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> getUsername() => _storage.read(key: _kUsername);

  /// [expiresInSeconds] : durée de vie du jeton d'accès annoncée par le
  /// serveur. Mémorisée en heure locale — insensible à un téléphone mal
  /// réglé — pour renouveler la session avant l'expiration.
  Future<void> saveTokens({
    required String accessToken,
    required String? refreshToken,
    int? expiresInSeconds,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    }
    if (expiresInSeconds != null) {
      await _storage.write(
          key: _kAccessExpiry,
          value: '${DateTime.now().add(Duration(seconds: expiresInSeconds)).millisecondsSinceEpoch}');
    } else {
      await _storage.delete(key: _kAccessExpiry);
    }
  }

  /// Expiration du jeton d'accès, `null` si le serveur ne l'a pas annoncée.
  Future<DateTime?> getAccessTokenExpiry() async {
    final ms = int.tryParse(await _storage.read(key: _kAccessExpiry) ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
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

  /// Refresh token sorti du coffre du code d'accès, le temps de la session.
  Future<void> saveRefreshToken(String refreshToken) =>
      _storage.write(key: _kRefreshToken, value: refreshToken);

  /// Mise sous clé : les jetons en clair disparaissent, seul le coffre chiffré
  /// du code d'accès les conserve. L'organisation de travail, elle, reste :
  /// le déverrouillage rouvre l'application là où elle était.
  Future<void> clearSessionTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kAccessExpiry);
  }

  /// Déconnexion volontaire : le coffre du code d'accès est conservé, mais le
  /// refresh token qu'il protège est révoqué. Au prochain lancement, il n'y a
  /// plus de session à rouvrir — on passe par la connexion, qui redemandera
  /// le code au lieu d'en faire choisir un nouveau.
  Future<bool> isLoggedOut() async =>
      (await _storage.read(key: _kDeconnecte)) == '1';

  Future<void> setLoggedOut(bool deconnecte) => deconnecte
      ? _storage.write(key: _kDeconnecte, value: '1')
      : _storage.delete(key: _kDeconnecte);

  /// Fin de session : jetons et organisation active partent ensemble, pour
  /// que le compte suivant ne démarre jamais dans l'organisation du précédent.
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kAccessExpiry);
    await _storage.delete(key: _kOrganisationId);
  }
}
