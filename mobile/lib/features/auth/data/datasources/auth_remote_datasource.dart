import '../../../../core/network/api_client.dart';

class AuthRemoteDatasource {
  final ApiClient _client;
  const AuthRemoteDatasource(this._client);

  /// POST /auth/login → { accessToken, refreshToken, expiresIn, … }
  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await _client.postPublic(
        '/auth/login', {'username': username, 'password': password});
    return data as Map<String, dynamic>;
  }

  Future<void> logout(String refreshToken) async {
    await _client.postPublic('/auth/logout', {'refreshToken': refreshToken});
  }
}
