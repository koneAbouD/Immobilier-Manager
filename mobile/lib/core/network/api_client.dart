import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:tmk_pin/tmk_pin.dart' show JwtClaims;

import '../cache/reponse_cache.dart';
import '../error/exception.dart';
import '../storage/secure_storage.dart';
import 'api_config.dart';
import 'diagnostic_reseau.dart';
import 'etat_reseau.dart';

/// Messages réseau présentés à l'utilisateur — volontairement clairs et sans
/// détail technique, qui n'aident pas l'utilisateur et font « bug ». Repris de
/// VTC Manager : chacun dit quoi faire selon la cause de l'échec.

/// Ni Wi-Fi ni données mobiles actifs (désactivés, mode avion) : il suffit
/// d'en activer un.
const String kMsgReseauDesactive =
    'Le Wi-Fi et les données mobiles sont désactivés. Activez l\'un des deux '
    '(et désactivez le mode avion), puis réessayez.';

/// Wi-Fi connecté, mais sans accès à internet.
const String kMsgWifiSansInternet =
    'Votre Wi-Fi est connecté mais n\'a pas accès à internet. Vérifiez la box '
    'ou passez sur les données mobiles, puis réessayez.';

/// Données mobiles actives, mais sans accès à internet.
const String kMsgDonneesSansInternet =
    'Les données mobiles sont activées mais n\'ont pas accès à internet '
    '(réseau faible ou forfait épuisé). Réessayez, ou connectez-vous à un '
    'Wi-Fi.';

/// Pas d'accès à internet, sans savoir par quel accès.
const String kMsgPasInternet =
    'Pas de connexion internet. Vérifiez le Wi-Fi ou les données mobiles, '
    'puis réessayez.';

/// Internet fonctionne, le serveur ne répond pas : inutile de toucher au
/// téléphone, il faut patienter.
const String kMsgServeurInjoignable =
    'Le serveur ne répond pas pour le moment. Votre connexion internet '
    'fonctionne : réessayez dans quelques instants.';

/// Cause impossible à établir (web) : on n'accuse ni l'un ni l'autre.
const String kMsgConnexionImpossible =
    'Impossible de joindre le serveur. Vérifiez votre connexion internet ; si '
    'elle fonctionne, le serveur est peut-être momentanément indisponible.';

/// Réponse 3xx : l'appel a été détourné avant d'atteindre le serveur — portail
/// d'un Wi-Fi public, forfait épuisé, proxy. Le backend n'en émet jamais.
const String kMsgAccesDetourne =
    'Le serveur est inaccessible depuis ce réseau. Sur un Wi-Fi public, '
    'ouvrez votre navigateur pour vous connecter, ou passez sur les données '
    'mobiles, puis réessayez.';

/// 502, 503, 504 : le proxy répond, pas le serveur derrière (redémarrage,
/// maintenance).
const String kMsgServeurIndisponible =
    'Le serveur est momentanément indisponible. Réessayez dans quelques '
    'instants.';

/// Message présenté pour une indisponibilité de [cause] donnée.
String messageIndisponibilite(CauseIndisponibilite cause) => switch (cause) {
      CauseIndisponibilite.reseauDesactive => kMsgReseauDesactive,
      CauseIndisponibilite.wifiSansInternet => kMsgWifiSansInternet,
      CauseIndisponibilite.donneesSansInternet => kMsgDonneesSansInternet,
      CauseIndisponibilite.reseau => kMsgPasInternet,
      CauseIndisponibilite.serveur => kMsgServeurInjoignable,
      CauseIndisponibilite.inconnue => kMsgConnexionImpossible,
    };

/// Client HTTP partagé par tous les datasources.
/// - Injecte automatiquement le Bearer token.
/// - Sur un 401, tente un refresh token puis rejoue la requête **une seule fois** ;
///   si le refresh échoue, signale la fin de session via [onSessionExpired].
/// - Lance [ApiException] pour les erreurs HTTP et [NetworkException] pour
///   les erreurs réseau (timeout, pas de connexion, portail Wi-Fi), dont
///   [DiagnosticReseau] établit la cause.
/// - Tient [EtatReseau] à jour pour le bandeau « hors connexion ».
/// - Sans serveur, rejoue la dernière réponse connue d'une lecture (voir [get]).
class ApiClient {
  final SecureStorage _storage;
  final http.Client _http;
  final EtatReseau _etat;
  final DiagnosticReseau _diagnostic;
  final ReponseCache _cache;

  /// Appelé quand la session ne peut plus être prolongée (refresh refusé).
  void Function()? onSessionExpired;

  /// Appelé à chaque renouvellement des jetons, avec le nouveau refresh
  /// token : le coffre du code d'accès le rechiffre.
  void Function(String refreshToken)? onTokensRenewed;

  /// Appelé quand l'organisation active n'est plus accessible (membre retiré,
  /// organisation à choisir) : l'application repasse par le choix d'organisation.
  void Function()? onOrganisationInaccessible;

  /// Appelé quand le rôle ne suffit pas pour une action (403 des règles
  /// d'autorisation) : le rôle a pu changer depuis l'ouverture de la session.
  void Function()? onDroitsRefuses;

  /// Codes du backend qui invalident l'organisation active.
  static const _codesOrganisationInaccessible = {
    'NON_MEMBRE',
    'AUCUNE_ORGANISATION',
    'ORGANISATION_A_PRECISER',
  };

  /// Entête portant l'organisation de travail : le backend y cloisonne
  /// chaque requête.
  static const enteteOrganisation = 'X-Organisation-Id';

  ApiClient(
    this._storage, [
    http.Client? client,
    EtatReseau? etat,
    DiagnosticReseau? diagnostic,
    ReponseCache? cache,
  ])  : _http = client ?? http.Client(),
        _etat = etat ?? EtatReseau.instance,
        _diagnostic = diagnostic ?? DiagnosticReseau.instance,
        _cache = cache ?? ReponseCache.instance;

  static const _timeout = Duration(seconds: 25);

  /// Un seul refresh à la fois : des requêtes parallèles qui reçoivent toutes
  /// un 401 attendent le même renouvellement au lieu d'en lancer chacune un.
  Future<bool>? _refreshEnCours;

  /// Lecture. Quand le serveur est hors d'atteinte (pas de réseau, portail
  /// Wi-Fi, maintenance), rejoue la dernière réponse connue de la même URL,
  /// dans la même organisation et pour le même compte, et signale au bandeau
  /// de quand elle date.
  ///
  /// Une réponse du serveur, même une erreur, l'emporte toujours : un 403 ou
  /// un 404 n'est jamais masqué par le cache.
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    // Lecture faite d'avance : seul compte ce qu'en dit le serveur, et sa
    // réponse rejoint le cache. Sans serveur, ni repli ni bandeau.
    if (enPrechargement) return _send('GET', path, query: query);
    try {
      return await _send('GET', path, query: query);
    } on NetworkException catch (e) {
      final secours = await _depuisLeCache(path, query, e.cause);
      if (secours == null) rethrow;
      return secours.donnees;
    } on ApiException catch (e) {
      if (!_serveurIndisponible(e.statusCode)) rethrow;
      final secours =
          await _depuisLeCache(path, query, CauseIndisponibilite.serveur);
      if (secours == null) rethrow;
      return secours.donnees;
    }
  }

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Object body) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Exécute [lectures] — des appels ordinaires de repository — en
  /// préchargement : chaque [get] va au serveur et sa réponse rejoint le
  /// cache, pour qu'un écran soit servi hors connexion sans avoir été ouvert.
  /// Sans serveur, rien ne se passe : ni repli sur le cache, ni bandeau —
  /// l'échec remonte seulement à l'appelant, qui arrête là.
  ///
  /// Repris de VTC Manager (`precharger`), mais à partir du code qui charge
  /// les écrans : l'URL et ses paramètres sont ainsi exactement les leurs.
  static Future<T> precharger<T>(Future<T> Function() lectures) =>
      runZoned(lectures, zoneValues: {_prechargement: true});

  /// Vrai pendant [precharger].
  static bool get enPrechargement => Zone.current[_prechargement] == true;

  static final _prechargement = Object();

  /// Fichier binaire (PDF…) : renvoie son contenu brut.
  Future<Uint8List> getBytes(String path) async {
    final response = await _executer(() async => http.Request('GET', _buildUri(path, null)),
        accept: '*/*');
    _verifier(response);
    return response.bodyBytes;
  }

  /// Envoi d'un fichier en `multipart/form-data` sous le champ [champ].
  Future<dynamic> postFichier(String path,
      {required String champ,
      required Uint8List contenu,
      required String nomFichier,
      required String type}) async {
    final response = await _executer(() async {
      final mime = type.split('/');
      return http.MultipartRequest('POST', _buildUri(path, null))
        ..files.add(http.MultipartFile.fromBytes(champ, contenu,
            filename: nomFichier, contentType: MediaType(mime[0], mime[1])));
    });
    _verifier(response);
    final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    return raw.isEmpty ? null : _tryJson(raw);
  }

  /// Appel sans jeton ni refresh (login, refresh, logout, inscription).
  Future<dynamic> postPublic(String path, Object body) =>
      _send('POST', path, body: body, authentifie: false);

  /// Lecture publique (formules d'abonnement à l'inscription).
  Future<dynamic> getPublic(String path) =>
      _send('GET', path, authentifie: false);

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
      final organisation = await _storage.getOrganisationId();
      if (organisation != null) headers[enteteOrganisation] = '$organisation';
    }

    final http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..followRedirects = false;
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(
          await _http.send(request).timeout(_timeout));
    } on TimeoutException catch (e) {
      throw await _echecConnexion(e);
    } on http.ClientException catch (e) {
      throw await _echecConnexion(e);
    }
    _constater(response.statusCode);
    if (method == 'GET' &&
        authentifie &&
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        _cachable(path)) {
      unawaited(_enregistrer(uri, headers, response.bodyBytes));
    }

    if (response.statusCode == 401 && authentifie && !rejeu) {
      if (await _refresh()) {
        return _send(method, path, body: body, query: query, rejeu: true);
      }
      onSessionExpired?.call();
    }

    final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    final parsed = raw.isEmpty ? null : _tryJson(raw);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsed;
    }
    final map = parsed is Map<String, dynamic> ? parsed : null;
    _signalerOrganisation(response.statusCode, map);
    throw ApiException(
      response.statusCode,
      _messageErreur(response.statusCode, map),
      code: map?['error'] as String?,
      body: map,
    );
  }

  void _signalerOrganisation(int status, Map<String, dynamic>? erreur) {
    final code = erreur?['error'];
    if (_codesOrganisationInaccessible.contains(code)) {
      onOrganisationInaccessible?.call();
    } else if (status == 403 && (code == null || code == 'ACCESS_DENIED')) {
      onDroitsRefuses?.call();
    }
  }

  /// Envoie la requête construite par [construire] avec le jeton ; sur un 401,
  /// renouvelle la session puis la reconstruit et la rejoue une fois (un corps
  /// de requête ne se relit pas, d'où la fabrique).
  Future<http.Response> _executer(Future<http.BaseRequest> Function() construire,
      {String accept = 'application/json', bool rejeu = false}) async {
    final request = await construire();
    request
      ..headers['Accept'] = accept
      ..followRedirects = false;
    final token = await _storage.getAccessToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final organisation = await _storage.getOrganisationId();
    if (organisation != null) request.headers[enteteOrganisation] = '$organisation';
    final http.Response response;
    try {
      // Un fichier peut être long à monter sur une connexion mobile.
      response = await http.Response.fromStream(
          await _http.send(request).timeout(_timeout * 3));
    } on TimeoutException catch (e) {
      throw await _echecConnexion(e);
    } on http.ClientException catch (e) {
      throw await _echecConnexion(e);
    }
    _constater(response.statusCode);
    if (response.statusCode == 401 && !rejeu) {
      if (await _refresh()) return _executer(construire, accept: accept, rejeu: true);
      onSessionExpired?.call();
    }
    return response;
  }

  /// Échec de connexion (délai dépassé, connexion refusée ou coupée, pas de
  /// réseau) : sa cause décide du message — activer le Wi-Fi ou les données,
  /// vérifier sa box, ou patienter.
  Future<NetworkException> _echecConnexion(Object erreur) async {
    final cause = await _diagnostic.causeDe(erreur);
    if (!enPrechargement) _etat.injoignable(cause);
    return NetworkException(messageIndisponibilite(cause), cause);
  }

  /// Une réponse HTTP est arrivée : dit au bandeau si le serveur est joignable.
  ///
  /// Une redirection (3xx) ne vient jamais du backend : c'est le réseau qui a
  /// intercepté l'appel (portail Wi-Fi…). Elle remonte comme une
  /// [NetworkException]. 502/503/504 : le proxy répond, le serveur non.
  void _constater(int status) {
    if (status >= 300 && status < 400) {
      if (!enPrechargement) _etat.injoignable(CauseIndisponibilite.reseau);
      throw const NetworkException(
          kMsgAccesDetourne, CauseIndisponibilite.reseau);
    }
    if (_serveurIndisponible(status)) {
      if (!enPrechargement) _etat.injoignable(CauseIndisponibilite.serveur);
    } else if (!enPrechargement) {
      // Un préchargement réussi n'efface pas le bandeau : les écrans affichés
      // montrent encore des données rejouées, qu'il ne rafraîchit pas.
      _etat.joignable();
    }
  }

  // ── Cache hors connexion ────────────────────────────────────────────────

  /// Au-delà, une lecture du cache est abandonnée : la base s'ouvre en
  /// quelques millisecondes, sauf incident.
  static const _attenteCache = Duration(seconds: 2);

  /// Les échanges d'authentification ne se rejouent jamais.
  static bool _cachable(String path) => !path.startsWith('/auth/');

  /// Clé d'une lecture : l'URL **et** l'organisation de travail, que l'URL ne
  /// porte pas (elle voyage dans l'en-tête [enteteOrganisation]). Sans elle,
  /// la liste des biens d'une organisation serait rejouée dans une autre.
  static String _cle(Uri uri, String? organisation) =>
      '${organisation ?? '-'}|$uri';

  /// Une lecture réussie devient la réponse de secours de son URL, rattachée
  /// au compte connecté.
  Future<void> _enregistrer(
      Uri uri, Map<String, String> headers, List<int> corps) async {
    await _cache.ecrire(
      _cle(uri, headers[enteteOrganisation]),
      corps,
      proprietaire: await _storage.getUsername(),
    );
  }

  Future<({Object? donnees})?> _depuisLeCache(
    String path,
    Map<String, String>? query,
    CauseIndisponibilite cause,
  ) async {
    if (!_cachable(path)) return null;
    final organisation = await _storage.getOrganisationId();
    final enCache = await _cache
        .lire(
          _cle(_buildUri(path, query), organisation?.toString()),
          proprietaire: await _storage.getUsername(),
        )
        .timeout(_attenteCache, onTimeout: () => null);
    if (enCache == null) return null;
    final donnees = enCache.corps.isEmpty
        ? null
        : _tryJson(utf8.decode(enCache.corps, allowMalformed: true));
    _etat.donneesDuCache(enCache.enregistreLe, cause);
    return (donnees: donnees);
  }

  static bool _serveurIndisponible(int status) =>
      status == 502 || status == 503 || status == 504;

  void _verifier(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final parsed = _tryJson(utf8.decode(response.bodyBytes, allowMalformed: true));
    final map = parsed is Map<String, dynamic> ? parsed : null;
    _signalerOrganisation(response.statusCode, map);
    throw ApiException(
      response.statusCode,
      _messageErreur(response.statusCode, map),
      code: map?['error'] as String?,
      body: map,
    );
  }

  /// Renouvelle la session à partir du refresh token enregistré : `true` si le
  /// serveur l'accepte, `false` s'il le refuse (session révoquée). Lève une
  /// [NetworkException] quand le serveur est hors d'atteinte — le
  /// déverrouillage ouvre alors l'application en consultation.
  Future<bool> renouvelerSession() => _refresh();

  Future<bool> _refresh() {
    return _refreshEnCours ??= _doRefresh().whenComplete(() {
      _refreshEnCours = null;
    });
  }

  /// Le serveur a-t-il réellement refusé le refresh token ?
  ///
  /// Seuls 400, 401 et 403 disent « session morte » : le backend traduit tout
  /// refus de Keycloak en 401. Le reste — 5xx du reverse proxy pendant un
  /// redéploiement, 503 quand Keycloak est injoignable, 429 — n'est qu'une
  /// panne passagère : conclure à une révocation ferait perdre la session à
  /// chaque redémarrage du serveur. (Repris de VTC Manager.)
  static bool refusDefinitif(int statusCode) =>
      statusCode == 400 || statusCode == 401 || statusCode == 403;

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final data =
          await postPublic('/auth/refresh', {'refreshToken': refreshToken});
      final acces = data is Map<String, dynamic> ? data['accessToken'] : null;
      if (acces is! String || acces.isEmpty) return false;
      final nouveau = (data as Map<String, dynamic>)['refreshToken'] as String?;
      await _storage.saveTokens(
        accessToken: acces,
        refreshToken: nouveau,
        expiresInSeconds: (data['expiresIn'] as num?)?.toInt(),
      );
      // Le coffre du code d'accès rechiffre le refresh token neuf.
      if (nouveau != null && nouveau.isNotEmpty) onTokensRenewed?.call(nouveau);
      unawaited(_planifierRenouvellement());
      return true;
    } on NetworkException {
      // Serveur hors d'atteinte : ce n'est pas une fin de session. L'erreur
      // remonte telle quelle à l'écran, les jetons sont conservés.
      rethrow;
    } on ApiException catch (e) {
      if (refusDefinitif(e.statusCode)) return false;
      // Panne passagère côté serveur : traitée comme une coupure.
      throw const NetworkException(
          kMsgServeurIndisponible, CauseIndisponibilite.serveur);
    } catch (_) {
      return false;
    }
  }

  // ── Renouvellement proactif ─────────────────────────────────────────────

  /// On renouvelle quand il reste ce quart de la durée de vie du jeton
  /// d'accès, et au plus tard [_avanceMin] avant son expiration : les écrans
  /// ne tombent pas sur un 401 à chaque fin de jeton.
  static const _fractionRestante = 0.25;
  static const _avanceMin = Duration(seconds: 30);
  static const _delaiMin = Duration(seconds: 5);

  bool _renouvellementActif = false;
  Timer? _minuteurRenouvellement;

  /// Session ouverte (déverrouillée) : le renouvellement proactif démarre.
  void demarrerRenouvellement() {
    _renouvellementActif = true;
    unawaited(_planifierRenouvellement());
  }

  /// Session verrouillée ou fermée : plus de jeton en clair à renouveler.
  void arreterRenouvellement() {
    _renouvellementActif = false;
    _minuteurRenouvellement?.cancel();
    _minuteurRenouvellement = null;
  }

  Future<void> _planifierRenouvellement() async {
    _minuteurRenouvellement?.cancel();
    if (!_renouvellementActif) return;
    final expiration = await _storage.getAccessTokenExpiry() ??
        _expirationDuJeton(await _storage.getAccessToken());
    if (expiration == null || !_renouvellementActif) return;
    final restant = expiration.difference(DateTime.now());
    if (restant <= Duration.zero) {
      unawaited(renouvelerMaintenant());
      return;
    }
    final parFraction = restant * (1 - _fractionRestante);
    final parAvance = restant - _avanceMin;
    var delai = parFraction < parAvance ? parFraction : parAvance;
    if (delai < _delaiMin) delai = _delaiMin;
    _minuteurRenouvellement = Timer(delai, () => unawaited(renouvelerMaintenant()));
  }

  /// Expiration lue dans le jeton (`exp`), à défaut de durée annoncée.
  static DateTime? _expirationDuJeton(String? jeton) {
    final exp = JwtClaims.parse(jeton).values['exp'];
    return exp is num
        ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
        : null;
  }

  /// Renouvelle la session tout de suite (minuteur, retour au premier plan).
  /// Refus du serveur : fin de session ; serveur hors d'atteinte : rien, le
  /// prochain appel réessaiera.
  Future<void> renouvelerMaintenant() async {
    if (!_renouvellementActif) return;
    try {
      if (!await _refresh() && _renouvellementActif) onSessionExpired?.call();
    } on NetworkException {
      // Jetons conservés ; le prochain appel ou retour au premier plan
      // retentera.
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
      400 => 'Requête invalide : vérifiez les informations saisies.',
      401 => 'Session expirée, veuillez vous reconnecter.',
      402 => 'Votre abonnement ne permet pas cette opération.',
      403 => 'Vous n\'avez pas les droits nécessaires pour cette action.',
      404 => 'Élément introuvable.',
      409 => 'Opération refusée : les données ont changé entre-temps. Rechargez puis réessayez.',
      413 => 'Le fichier est trop volumineux. Choisissez un fichier plus léger.',
      422 => 'Une des valeurs saisies n\'est pas acceptée.',
      502 || 503 || 504 => kMsgServeurIndisponible,
      >= 500 => 'Le serveur a rencontré une erreur. Réessayez dans un instant.',
      _ => 'Réponse inattendue du serveur ($status). Réessayez dans un instant.',
    };
  }
}
