import 'package:flutter/widgets.dart';

/// Barre de navigation système (Android : gestes ou trois boutons ; iOS :
/// indicateur d'accueil).
///
/// L'application est affichée bord à bord : le contenu passe sous la barre de
/// navigation, qui reste transparente. Chaque liste ajoute donc cette hauteur
/// à sa marge basse, pour que son dernier élément s'arrête au-dessus de la
/// barre tout en laissant le défilement glisser dessous.
extension InsetsSysteme on BuildContext {
  /// Hauteur à réserver en bas de l'écran.
  ///
  /// Vaut 0 quand le clavier est ouvert (il couvre déjà la barre) ou quand un
  /// [SafeArea] parent a déjà protégé le bas : jamais de double marge.
  double get basSysteme => MediaQuery.paddingOf(this).bottom;
}
