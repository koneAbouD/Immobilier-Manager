import 'package:flutter/foundation.dart';

/// Sorties de l'application qu'elle a elle-même lancées : appareil photo,
/// choix d'un fichier, partage, WhatsApp, itinéraire, appel, impression.
///
/// Toute autre sortie (écran d'accueil, autre application) remet aussitôt la
/// session sous clé ; celles-ci, non — l'application attend un résultat ou
/// sait que l'utilisateur va revenir. Repris du `SessionManager` de VTC
/// Manager (`sortieAttendue`).
class SortiesApplication {
  SortiesApplication._();

  static final instance = SortiesApplication._();

  /// Une sortie lancée par l'application peut quitter l'écran juste après que
  /// son appel a rendu la main (lien ouvert dans une autre application) : elle
  /// reste « voulue » pendant ce délai — il suffit que l'écran commence à
  /// céder la place (inactive) dans ce délai.
  static const delaiApresSortie = Duration(seconds: 3);

  int _enCours = 0;
  DateTime? _finDerniere;

  DateTime Function() _maintenant = DateTime.now;

  @visibleForTesting
  set horloge(DateTime Function() horloge) => _maintenant = horloge;

  @visibleForTesting
  void reinitialiser() {
    _enCours = 0;
    _finDerniere = null;
    _maintenant = DateTime.now;
  }

  /// Exécute [action], qui fait quitter l'application pour y revenir : cette
  /// sortie-là ne verrouille pas.
  static Future<T> attendue<T>(Future<T> Function() action) =>
      instance._attendue(action);

  Future<T> _attendue<T>(Future<T> Function() action) async {
    _enCours++;
    try {
      return await action();
    } finally {
      _enCours--;
      _finDerniere = _maintenant();
    }
  }

  /// Une sortie voulue est-elle en cours, ou vient-elle de rendre la main ?
  bool get voulue {
    if (_enCours > 0) return true;
    final fin = _finDerniere;
    return fin != null && _maintenant().difference(fin) < delaiApresSortie;
  }
}
