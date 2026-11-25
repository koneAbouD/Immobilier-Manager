import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'diagnostic_reseau.dart';

/// Le serveur est-il hors d'atteinte, et pourquoi ?
///
/// `null` quand tout va bien ; sinon la cause du dernier échec de connexion.
/// Le client HTTP la tient à jour — un échec réseau la pose, toute réponse du
/// serveur (même une erreur 4xx) l'efface — et le [BandeauHorsLigne] l'affiche.
///
/// [donneesDu] dit, quand des écrans affichent des réponses rejouées depuis
/// le cache faute de serveur, de quand date la plus ancienne. Pendant de
/// `EtatHorsLigne` de VTC Manager.
class EtatReseau extends ValueNotifier<CauseIndisponibilite?> {
  EtatReseau() : super(null);

  static EtatReseau instance = EtatReseau();

  StreamSubscription<List<ConnectivityResult>>? _ecoute;

  DateTime? _donneesDu;

  /// Heure de la plus ancienne réponse servie depuis le cache depuis la
  /// dernière réponse du serveur ; `null` si rien n'a été rejoué.
  DateTime? get donneesDu => _donneesDu;

  /// Un appel n'a pas pu joindre le serveur.
  void injoignable(CauseIndisponibilite cause) => value = cause;

  /// Faute de serveur, un écran affiche une réponse du cache enregistrée à
  /// [le].
  void donneesDuCache(DateTime le, CauseIndisponibilite cause) {
    final actuel = _donneesDu;
    if (actuel == null || le.isBefore(actuel)) _donneesDu = le;
    if (value == cause) {
      notifyListeners();
    } else {
      value = cause;
    }
  }

  /// Le serveur a répondu : la liaison est rétablie, les écrans rechargés
  /// affichent des données fraîches.
  void joignable() {
    _donneesDu = null;
    value = null;
  }

  /// Suit les bascules Wi-Fi / données du téléphone, pour réagir sans
  /// attendre le prochain appel :
  /// - tout coupé (mode avion…) : le bandeau le dit aussitôt ;
  /// - un accès revient ou change (Wi-Fi ↔ données) : le bandeau s'efface,
  ///   le prochain appel dira s'il reste un problème.
  ///
  /// Lancé par `main()` seulement : le greffon n'existe pas dans les tests.
  void suivreAccesReseau([Stream<List<ConnectivityResult>>? bascules]) {
    _ecoute ??= (bascules ?? Connectivity().onConnectivityChanged).listen(
      (resultats) => accesChange(accesDepuis(resultats)),
      onError: (Object _) {},
    );
  }

  @visibleForTesting
  void accesChange(AccesReseau acces) {
    if (acces == AccesReseau.aucun) {
      value = CauseIndisponibilite.reseauDesactive;
    } else if (_donneesDu == null) {
      value = null;
    }
    // Des données rejouées restent affichées : le bandeau garde leur heure
    // jusqu'à ce que le serveur réponde de nouveau.
  }

  @override
  void dispose() {
    _ecoute?.cancel();
    super.dispose();
  }
}
