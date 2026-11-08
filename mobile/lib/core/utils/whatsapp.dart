/// Ouverture de WhatsApp sur une conversation, message pré-rempli.
///
/// C'est une **redirection**, pas un envoi : WhatsApp s'ouvre sur le
/// destinataire avec le texte déjà écrit, et c'est le gestionnaire qui appuie
/// sur envoyer. Le lien `wa.me` ne transporte que du texte : aucune pièce
/// jointe n'est possible par ce chemin. (Repris de VTC Manager.)
library;

import 'package:url_launcher/url_launcher.dart';

import 'telephone.dart';

/// Le lien qui ouvre la conversation de [telephone], message pré-rempli. Sans
/// numéro exploitable, WhatsApp s'ouvre sur son sélecteur de contacts.
///
/// Le message est encodé composant par composant : les `queryParameters` de
/// [Uri] rendent les espaces en « + », que WhatsApp ne redécode pas toujours.
Uri lienWhatsApp({String? telephone, required String message}) {
  final numero = telephoneInternational(telephone);
  return Uri.parse('https://wa.me/${numero ?? ''}?text=${Uri.encodeComponent(message)}');
}

/// Ouvre WhatsApp sur la conversation de [telephone] avec [message] pré-rempli.
/// Retourne false si aucune application ne sait ouvrir le lien.
Future<bool> ouvrirWhatsApp({String? telephone, required String message}) =>
    launchUrl(lienWhatsApp(telephone: telephone, message: message), mode: LaunchMode.externalApplication);
