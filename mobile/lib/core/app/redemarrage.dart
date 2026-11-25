/// Redémarrage à chaud de l'application : un conteneur Riverpod neuf, donc
/// aucune donnée en cache. Utilisé à chaque ouverture de session et à chaque
/// changement d'organisation : les listes d'une organisation (ou d'un compte)
/// ne doivent jamais s'afficher dans une autre.
///
/// La racine de l'application ([main.dart]) enregistre l'action au démarrage.
class Redemarrage {
  Redemarrage._();

  static Future<void> Function()? _action;

  static void enregistrer(Future<void> Function() action) => _action = action;

  static Future<void> lancer() async => _action?.call();

  /// Vrai quand la racine de l'application a enregistré l'action (toujours,
  /// sauf dans les tests qui montent un écran seul).
  static bool get enregistre => _action != null;
}
