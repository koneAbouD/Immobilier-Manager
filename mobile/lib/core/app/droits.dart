import 'package:flutter/widgets.dart';

import '../../features/organisation/domain/entities/organisation.dart';

export '../../features/organisation/domain/entities/organisation.dart' show ActionMetier, RoleMembre;

/// Droits de l'utilisateur dans l'organisation active : son rôle, croisé avec
/// ce que l'abonnement permet (la lecture seule coupe toute écriture).
///
/// Posé au-dessus du navigateur (dans `MaterialApp.builder`) pour atteindre
/// toutes les pages. Les briques communes (bouton « + » des listes, actions
/// « Modifier / Supprimer » des fiches) s'effacent d'elles-mêmes ; le backend
/// refuse de toute façon les opérations non autorisées.
class Droits extends InheritedWidget {
  final RoleMembre role;

  /// Faux quand l'abonnement ne laisse que la consultation.
  final bool ecritureOuverte;

  const Droits({super.key, required this.role, required this.ecritureOuverte, required super.child});

  bool autorise(ActionMetier action) => ecritureOuverte && role.peut(action);

  /// Vrai si l'utilisateur peut faire [action]. Vrai hors de tout [Droits]
  /// (écrans d'authentification).
  static bool peut(BuildContext context, ActionMetier action) =>
      context.dependOnInheritedWidgetOfExactType<Droits>()?.autorise(action) ?? true;

  /// Raccourci pour [ActionMetier.ecrire] : créer et modifier.
  static bool ecriture(BuildContext context) => peut(context, ActionMetier.ecrire);

  @override
  bool updateShouldNotify(Droits oldWidget) =>
      role != oldWidget.role || ecritureOuverte != oldWidget.ecritureOuverte;
}
