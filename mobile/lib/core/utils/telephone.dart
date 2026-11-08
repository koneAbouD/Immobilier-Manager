/// Numéros de téléphone ivoiriens : forme internationale pour WhatsApp.
library;

const _indicatifCI = '225';

/// Un numéro ivoirien compte 10 chiffres depuis 2021.
const _longueurLocaleCI = 10;

/// En deçà, ce n'est pas un numéro joignable (saisie tronquée, champ vide…).
const _minimumJoignable = 8;

final _nonChiffre = RegExp(r'[^0-9]');

/// Numéro international, chiffres seuls (« 2250707010203 »), ou null s'il
/// n'est pas exploitable.
///
/// « +225 07… » ou « 00225 07… » : ce qui est déjà international est conservé ;
/// un numéro local reçoit l'indicatif de la Côte d'Ivoire. (Repris de VTC Manager.)
String? telephoneInternational(String? brut, {String indicatif = _indicatifCI}) {
  final s = (brut ?? '').trim();
  final d = s.replaceAll(_nonChiffre, '');
  if (d.length < _minimumJoignable) return null;
  if (s.startsWith('+')) return d;
  if (d.startsWith('00')) return d.substring(2);
  // « 22 51 23 45 67 » est un numéro local qui commence par 225 : seul un
  // numéro plus long que le format local est déjà international.
  if (d.startsWith(indicatif) && d.length > _longueurLocaleCI) return d;
  return '$indicatif$d';
}
