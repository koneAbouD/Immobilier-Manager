import 'package:flutter/services.dart';

/// Séparateur de milliers des champs de saisie : espace insécable, que
/// [parseMontantSaisi] ignore à la relecture.
const kSeparateurMilliers = ' ';

/// « 1500000 » → « 1 500 000 » (chiffres seuls).
String grouperMilliers(String chiffres) {
  final b = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) b.write(kSeparateurMilliers);
    b.write(chiffres[i]);
  }
  return b.toString();
}

/// Valeur initiale d'un champ montant : 150000 → « 150 000 », null → vide.
String saisieMontant(num? montant) {
  if (montant == null) return '';
  final entier = montant.round();
  final texte = grouperMilliers(entier.abs().toString());
  return entier < 0 ? '-$texte' : texte;
}

/// Regroupe les chiffres par milliers pendant la frappe (« 1 500 000 ») en
/// gardant le curseur à sa place. Seuls les chiffres sont acceptés.
class SeparateurMilliersFormatter extends TextInputFormatter {
  const SeparateurMilliersFormatter();

  static final _nonChiffre = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue ancien, TextEditingValue nouveau) {
    var texte = nouveau.text;
    var curseur = nouveau.selection.isValid
        ? nouveau.selection.extentOffset.clamp(0, texte.length)
        : texte.length;

    // Retour arrière sur un séparateur : il reviendrait aussitôt. On efface
    // donc le chiffre qui le précède, comme l'attend l'utilisateur.
    final effaceSeparateur = texte.length == ancien.text.length - 1 &&
        texte.replaceAll(_nonChiffre, '') == ancien.text.replaceAll(_nonChiffre, '') &&
        curseur > 0;
    if (effaceSeparateur) {
      var i = curseur - 1;
      while (i >= 0 && _nonChiffre.hasMatch(texte[i])) {
        i--;
      }
      if (i >= 0) {
        texte = texte.substring(0, i) + texte.substring(i + 1);
        curseur = i;
      }
    }

    // Nombre de chiffres avant le curseur : c'est lui qui fixe sa place.
    var avant = texte.substring(0, curseur).replaceAll(_nonChiffre, '').length;
    var chiffres = texte.replaceAll(_nonChiffre, '');
    // Pas de zéros en tête (« 00 150 ») : « 0 » seul reste permis.
    final zeros = RegExp(r'^0+(?=\d)').firstMatch(chiffres)?.end ?? 0;
    if (zeros > 0) {
      chiffres = chiffres.substring(zeros);
      avant = (avant - zeros).clamp(0, chiffres.length);
    }

    final groupe = grouperMilliers(chiffres);
    var position = 0;
    for (var vus = 0; position < groupe.length && vus < avant; position++) {
      if (groupe[position] != kSeparateurMilliers) vus++;
    }
    return TextEditingValue(
      text: groupe,
      selection: TextSelection.collapsed(offset: position),
    );
  }
}
