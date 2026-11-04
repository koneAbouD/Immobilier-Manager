import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/exception.dart';
import '../storage/secure_storage.dart';
import 'api_config.dart';

/// Messages réseau présentés à l'utilisateur — volontairement clairs et sans
/// détail technique, qui n'aident pas l'utilisateur et font « bug ».
const String kMsgServeurTimeout =
    'Le serveur met trop de temps à répondre. Vérifiez votre connexion, puis réessayez.';
const String kMsgServeurInjoignable =
    'Impossible de joindre le serveur. Vérifiez votre connexion internet, puis réessayez.';

/// Client HTTP partagé par tous les datasources.
/// - Injecte automatiquement le Bearer token.
/// - Sur un 401, tente un refresh token puis rejoue la requête **une seule fois** ;
///   si le refresh échoue, signale la fin de session via [onSessionExpired].
/// - Lance [ApiException] pour les erreurs HTTP et [NetworkException] pour
///   les erreurs réseau (timeout, pas de connexion).
class ApiClient {
  final SecureStorage _storage;
  final http.Client _http;

  /// Appelé quand la session ne peut plus être prolongée (refresh refusé).
  void Function()? onSessionExpired;

  ApiClient(this._storage, [http.Client? client])
      : _http = client ?? http.Client();

  static const _timeout = Duration(seconds: 25);

  /// Un seul refresh à la fois : des requêtes parallèles qui reçoivent toutes
  /// un 401 attendent le même renouvellement au lieu d'en lancer chacune un.
  Future<bool>? _refreshEnCours;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Object body) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Appel sans jeton ni refresh (login, refresh, logout).
  Future<dynamic> postPublic(String path, Object body) =>
      _send('POST', path, body: body, authentifie: false);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authentifie = true,
    bool rejeu = false,
  }) async {
    final uri = _buildUri(path, query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (authentifie) {
      final token = await _storage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(
          await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw const NetworkException(kMsgServeurTimeout);
    } on http.ClientException {
      throw const NetworkException(kMsgServeurInjoignable);
    }

    if (response.statusCode == 401 && authentifie && !rejeu) {
      if (await _refresh()) {
        return _send(method, path, body: body, query: query, rejeu: true);
      }
      onSessionExpired?.call();
    }

    final raw = utf8.decode(response.bodyBytes);
    final parsed = raw.isEmpty ? null : _tryJson(raw);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsed;
    }
    final map = parsed is Map<String, dynamic> ? parsed : null;
    throw ApiException(
      response.statusCode,
      _messageErreur(response.statusCode, map),
      code: map?['error'] as String?,
      body: map,
    );
  }

  Future<bool> _refresh() {
    return _refreshEnCours ??= _doRefresh().whenComplete(() {
      _refreshEnCours = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final data = await postPublic('/auth/refresh', {'refreshToken': refreshToken});
      if (data is! Map<String, dynamic>) return false;
      await _storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String?,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  static dynamic _tryJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Priorité au message du backend (ApiError.message), déjà rédigé pour
  /// l'utilisateur ; à défaut, un message générique par statut.
  static String _messageErreur(int status, Map<String, dynamic>? body) {
    final message = body?['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return switch (status) {
      401 => 'Session expirée, veuillez vous reconnecter.',
      403 => 'Vous n\'avez pas les droits nécessaires pour cette action.',
      404 => 'Élément introuvable.',
      >= 500 => 'Le serveur a rencontré une erreur. Réessayez dans un instant.',
      _ => 'La requête a échoué ($status).',
    };
  }
}
