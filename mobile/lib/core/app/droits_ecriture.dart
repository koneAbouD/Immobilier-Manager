import 'package:flutter/widgets.dart';

/// Droit d'écriture de l'utilisateur dans l'organisation active : faux pour un
/// lecteur, ou quand l'abonnement ne laisse que la consultation.
///
/// Posé au-dessus du navigateur (dans `MaterialApp.builder`) pour atteindre
/// toutes les pages. Les briques communes (bouton « + » des listes, actions
/// « Modifier / Supprimer » des fiches) s'effacent d'elles-mêmes ; le backend
/// refuse de toute façon les écritures non autorisées.
class DroitsEcriture extends InheritedWidget {
  final bool peutEcrire;

  const DroitsEcriture({super.key, required this.peutEcrire, required super.child});

  /// Vrai hors de tout [DroitsEcriture] (écrans d'authentification).
  static bool de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DroitsEcriture>()?.peutEcrire ?? true;

  @override
  bool updateShouldNotify(DroitsEcriture oldWidget) => peutEcrire != oldWidget.peutEcrire;
}
