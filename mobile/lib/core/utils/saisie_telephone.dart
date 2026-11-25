import 'package:flutter/services.dart';

/// Saisie des numéros ivoiriens : chiffres groupés par deux pendant la frappe
/// (« 07 07 12 34 56 », « +225 07 07 12 34 56 »). Le serveur ramène le numéro
/// à sa forme canonique ; l'application lui envoie de toute façon les chiffres
/// seuls ([telephoneSaisi]).

const _indicatifCI = '225';

/// Un numéro ivoirien compte 10 chiffres depuis 2021.
const kChiffresTelephoneCI = 10;

/// Longueur maximale d'un numéro international (norme E.164).
const _maxInternational = 15;

final _nonChiffre = RegExp(r'\D');

/// Saisie qui n'est visiblement pas un numéro (e-mail, identifiant) : laissée telle quelle.
final _pasUnNumero = RegExp(r'[^0-9+ ]');

/// Forme affichée d'un numéro : « 0707123456 » → « 07 07 12 34 56 ».
/// Les chiffres au-delà de la longueur permise sont coupés.
String formaterTelephone(String brut) {
  final texte = brut.trimLeft();
  final plus = texte.startsWith('+');
  var chiffres = texte.replaceAll(_nonChiffre, '');
  var prefixe = plus ? '+' : '';
  if (!plus && chiffres.startsWith('00')) {
    prefixe = '00';
    chiffres = chiffres.substring(2);
  }
  if (prefixe.isEmpty) return _parDeux(_couper(chiffres, kChiffresTelephoneCI));
  if (chiffres.startsWith(_indicatifCI)) {
    final national = _couper(chiffres.substring(_indicatifCI.length), kChiffresTelephoneCI);
    return national.isEmpty ? '$prefixe$_indicatifCI' : '$prefixe$_indicatifCI ${_parDeux(national)}';
  }
  // Autre pays : son découpage n'est pas connu, les chiffres restent d'un bloc.
  return '$prefixe${_couper(chiffres, _maxInternational)}';
}

/// Valeur initiale d'un champ téléphone : 0707123456 → « 07 07 12 34 56 ».
String saisieTelephone(String? stocke) {
  if (stocke == null || stocke.isEmpty) return '';
  return _pasUnNumero.hasMatch(stocke) ? stocke : formaterTelephone(stocke);
}

/// Numéro à envoyer : séparateurs retirés (« +225 07 07… » → « +2250707… »),
/// nul si le champ est vide.
String? telephoneSaisi(String texte) {
  final t = texte.trim();
  if (t.isEmpty) return null;
  return _pasUnNumero.hasMatch(t) ? t : t.replaceAll(' ', '');
}

/// Vérifie un numéro saisi : 10 chiffres pour un numéro ivoirien, 8 à 15
/// pour un numéro étranger. Vide : erreur seulement si [obligatoire].
String? verifierTelephone(String? valeur, {bool obligatoire = false}) {
  final t = (valeur ?? '').trim();
  if (t.isEmpty) return obligatoire ? 'Téléphone obligatoire.' : null;
  if (_pasUnNumero.hasMatch(t)) return 'Chiffres uniquement (ex. 07 07 12 34 56).';
  var chiffres = t.replaceAll(_nonChiffre, '');
  final international = t.startsWith('+') || chiffres.startsWith('00');
  if (chiffres.startsWith('00')) chiffres = chiffres.substring(2);
  if (!international || chiffres.startsWith(_indicatifCI)) {
    final national = international ? chiffres.substring(_indicatifCI.length) : chiffres;
    return national.length == kChiffresTelephoneCI
        ? null
        : 'Le numéro compte $kChiffresTelephoneCI chiffres (ex. 07 07 12 34 56).';
  }
  return chiffres.length >= 8 && chiffres.length <= _maxInternational ? null : 'Numéro international invalide.';
}

String _couper(String chiffres, int max) => chiffres.length > max ? chiffres.substring(0, max) : chiffres;

String _parDeux(String chiffres) {
  final b = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && i.isEven) b.write(' ');
    b.write(chiffres[i]);
  }
  return b.toString();
}

/// Groupe les chiffres par deux pendant la frappe en gardant le curseur à sa
/// place. Une saisie qui contient autre chose (lettres, « @ ») n'est pas
/// touchée : le formateur convient aussi à un champ « téléphone ou e-mail ».
class TelephoneFormatter extends TextInputFormatter {
  const TelephoneFormatter();

  /// Caractères qui comptent pour la place du curseur.
  static bool _significatif(String c) => c != ' ';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue ancien, TextEditingValue nouveau) {
    var texte = nouveau.text;
    if (_pasUnNumero.hasMatch(texte)) return nouveau;
    var curseur = nouveau.selection.isValid ? nouveau.selection.extentOffset.clamp(0, texte.length) : texte.length;

    // Retour arrière sur un espace : il reviendrait aussitôt. On efface donc
    // le chiffre qui le précède, comme l'attend l'utilisateur.
    final effaceEspace = texte.length == ancien.text.length - 1 &&
        texte.replaceAll(' ', '') == ancien.text.replaceAll(' ', '') &&
        curseur > 0;
    if (effaceEspace) {
      var i = curseur - 1;
      while (i >= 0 && texte[i] == ' ') {
        i--;
      }
      if (i >= 0) {
        texte = texte.substring(0, i) + texte.substring(i + 1);
        curseur = i;
      }
    }

    final avant = texte.substring(0, curseur).split('').where(_significatif).length;
    final forme = formaterTelephone(texte);
    var position = 0;
    for (var vus = 0; position < forme.length && vus < avant; position++) {
      if (_significatif(forme[position])) vus++;
    }
    return TextEditingValue(text: forme, selection: TextSelection.collapsed(offset: position));
  }
}
