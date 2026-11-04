import 'package:flutter/foundation.dart';

/// Configuration réseau centralisée.
///
/// Résolution de l'URL de base, par ordre de priorité :
///   1. --dart-define=API_BASE_URL=...      (URL complète, écrase tout)
///   2. --dart-define=DEV_HOST=192.168.x.x  (host seul, port 8082)
///   3. Build RELEASE  → serveur de production (_prodBaseUrl)
///   4. Build DEBUG    → localhost (développement local)
///
/// Sur un vrai téléphone Android en debug : `adb reverse tcp:8082 tcp:8082`.
class ApiConfig {
  static const _port = 8082;

  /// URL de l'API en production — à renseigner au premier déploiement.
  static const String _prodBaseUrl = 'https://immobilier.example.com/api';

  static const String _urlOverride = String.fromEnvironment('API_BASE_URL');
  static const String _hostOverride = String.fromEnvironment('DEV_HOST');

  static String get baseUrl {
    if (_urlOverride.isNotEmpty) return _strip(_urlOverride);
    if (_hostOverride.isNotEmpty) {
      return 'http://${_hostOverride.trim()}:$_port/api';
    }
    if (kReleaseMode) return _prodBaseUrl;
    return 'http://localhost:$_port/api';
  }

  static String _strip(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
