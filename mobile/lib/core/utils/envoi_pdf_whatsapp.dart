/// Envoi d'un document PDF à un locataire par WhatsApp (quittance…).
///
/// Avec un numéro, l'écran va droit à la conversation du locataire : le PDF est
/// enregistré sur l'appareil, WhatsApp s'ouvre sur la conversation, message
/// prêt, et le gestionnaire y joint le fichier. C'est le seul chemin qui mène
/// sûrement au bon destinataire — le lien wa.me — mais il ne transporte que du
/// texte : WhatsApp ignore tout destinataire joint à un partage de fichier.
///
/// Sans numéro, le contact est à choisir de toute façon : le PDF part alors
/// déjà joint, et WhatsApp demande le destinataire.
///
/// Rien n'est enregistré côté serveur : c'est le gestionnaire qui appuie sur
/// envoyer, et rien ne revient le confirmer. (Repris de VTC Manager.)
library;

import 'dart:typed_data';

import 'bytes_downloader.dart';
import 'partage_fichier.dart';
import 'telephone.dart';
import 'whatsapp.dart';

sealed class IssueEnvoiPdf {
  const IssueEnvoiPdf();
}

/// Le PDF est parti joint vers WhatsApp — ou vers la feuille de partage, faute
/// de WhatsApp — et le contact est à choisir.
class PdfPartage extends IssueEnvoiPdf {
  final bool dansWhatsApp;
  const PdfPartage({required this.dansWhatsApp});
}

/// Le PDF est enregistré sur l'appareil, et WhatsApp ouvert sur la conversation
/// avec le message : le gestionnaire y joint le fichier.
class PdfEnregistre extends IssueEnvoiPdf {
  final String? emplacement;

  /// Faux si WhatsApp n'a pas pu s'ouvrir : le fichier, lui, est bien enregistré.
  final bool conversationOuverte;

  const PdfEnregistre(this.emplacement, {this.conversationOuverte = true});
}

/// Le PDF n'a pas été produit : rien n'est parti.
class PdfIndisponible extends IssueEnvoiPdf {
  final String motif;
  const PdfIndisponible(this.motif);
}

/// Met le PDF [octets] entre les mains du gestionnaire, dans WhatsApp, avec
/// [message]. [document] nomme le fichier dans l'annonce : « Quittance ».
Future<IssueEnvoiPdf> envoyerPdfParWhatsApp({
  required Uint8List octets,
  required String nomFichier,
  required String message,
  required String document,
  String? telephone,
}) async {
  // Sans numéro, le contact est à choisir de toute façon : autant que le
  // document arrive déjà joint.
  if (telephoneInternational(telephone) == null) {
    switch (await partagerFichier(octets: octets, nomFichier: nomFichier, texte: message)) {
      case IssuePartage.whatsapp:
        return const PdfPartage(dansWhatsApp: true);
      case IssuePartage.feuilleDePartage:
        return const PdfPartage(dansWhatsApp: false);
      case IssuePartage.indisponible:
        break; // iOS, web : même chemin qu'avec un numéro.
    }
  }

  final emplacement = await downloadBytesFile(octets, nomFichier, 'application/pdf');
  // Annoncé avant de passer la main : le toast reste lisible par-dessus
  // WhatsApp, et dit où trouver le fichier à joindre.
  await annoncerSurAppareil(_dansTelechargements(emplacement)
      ? '$document enregistrée dans Téléchargements : joignez-la avec 📎 dans la conversation.'
      : '$document PDF enregistrée : joignez-la avec 📎 dans la conversation.');

  var ouverte = false;
  try {
    ouverte = await ouvrirWhatsApp(telephone: telephone, message: message);
  } catch (_) {
    // Le PDF est enregistré : l'écran dira que WhatsApp ne s'est pas ouvert.
  }
  return PdfEnregistre(emplacement, conversationOuverte: ouverte);
}

bool _dansTelechargements(String? emplacement) =>
    emplacement != null && (emplacement.startsWith('Téléchargements') || emplacement.contains('/Download'));
