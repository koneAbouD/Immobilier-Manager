import 'dart:async';

import 'package:immobilier_manager/core/cache/chiffreur_cache.dart';
import 'package:immobilier_manager/core/cache/reponse_cache.dart';
import 'package:immobilier_manager/core/cache/stockage_reponses.dart';
import 'package:immobilier_manager/core/network/diagnostic_reseau.dart';

/// Configuration commune à tous les tests de ce dossier.
///
/// - Le cache des réponses passe en mémoire : sa base SQLite ne répond pas
///   dans l'environnement des tests de widgets.
/// - Le diagnostic réseau ne sonde pas internet : la vraie sonde ouvrirait
///   une connexion vers l'extérieur, et l'accès réseau passe par un greffon
///   absent des tests. En test : « pas d'internet » sur un accès inconnu ; les
///   tests qui en dépendent injectent les leurs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ReponseCache.instance = ReponseCache(
    stockage: StockageMemoire(),
    chiffreur: ChiffreurCache.avecCle(List.filled(32, 0)),
  );
  DiagnosticReseau.instance = DiagnosticReseau(
    sonde: () async => false,
    acces: () async => AccesReseau.inconnu,
  );
  await testMain();
}
