import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/envoi_pdf_whatsapp.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/capture_document.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';
import '../providers/loyer_providers.dart';

/// Nom qui signe le message de quittance ; le PDF, rendu par le serveur, porte
/// le nom du bailleur configuré (app.bailleur.nom).
const nomEntrepriseQuittance = 'TMK';

/// Message qui accompagne la quittance dans WhatsApp, au format WhatsApp
/// (`*gras*`) : le montant reçu d'abord, le loyer concerné, puis ce qui reste
/// dû sur ce loyer. Les champs absents sont omis. (Gabarit du reçu de VTC Manager.)
String composerQuittance(Echeance e, Paiement p) {
  final prenom = e.locataireNom.trim().split(RegExp(r'\s+')).first;
  final mois = formatMois(e.periode).toLowerCase();
  final mode = switch (p.modePaiement) {
    ModePaiement.especes => 'en espèces',
    ModePaiement.mobileMoney => 'par Mobile Money',
    ModePaiement.virement => 'par virement',
    ModePaiement.cheque => 'par chèque',
  };
  final reception = [
    'nous avons bien reçu *${formatMontant(p.montant)}*',
    if (p.datePaiement != null) 'le ${formatDate(p.datePaiement)}',
    mode,
  ].join(' ');
  final local = e.logement.isEmpty ? '' : ' — ${e.logement}';
  final solde = e.resteDu <= 0
      ? 'Votre loyer de $mois est réglé. Merci !'
      : 'Reste à payer sur ce loyer : *${formatMontant(e.resteDu)}*';
  return [
    '✅ *Paiement reçu — $nomEntrepriseQuittance*',
    [prenom.isEmpty ? 'Bonjour,' : 'Bonjour $prenom,', '$reception.', '• Loyer de $mois$local'].join('\n'),
    [
      solde,
      if (p.reference != null && p.reference!.trim().isNotEmpty) 'Réf. ${p.reference!.trim()}',
    ].join('\n'),
    '📎 Votre quittance vous est envoyée en PDF.',
    'Merci de votre confiance.',
  ].join('\n\n');
}

/// « Quittance_fatou_bamba_novembre-2026.pdf ».
String nomFichierQuittance(Echeance e) {
  String slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'Quittance_${slug(e.locataireNom)}_${slug(formatMois(e.periode)).replaceAll('_', '-')}.pdf';
}

/// Produit la quittance du paiement [p] et la met entre les mains du
/// gestionnaire, dans WhatsApp, sur la conversation du locataire.
Future<void> envoyerQuittanceWhatsApp(BuildContext context, WidgetRef ref, Echeance e, Paiement p) async {
  final pdf = await ref.read(loyerRepositoryProvider).quittance(p.id!);
  if (!context.mounted) return;
  final issue = await pdf.fold<Future<IssueEnvoiPdf>>(
    (f) async => PdfIndisponible(f.message),
    (octets) => envoyerPdfParWhatsApp(
      octets: octets,
      nomFichier: nomFichierQuittance(e),
      message: composerQuittance(e, p),
      document: 'Quittance',
      telephone: e.locataireTelephone,
    ),
  );
  if (!context.mounted) return;
  switch (issue) {
    case PdfIndisponible(:final motif):
      showError(context, 'Quittance indisponible : $motif');
    case PdfEnregistre(conversationOuverte: false):
      showError(context, 'Quittance enregistrée, mais WhatsApp n\'a pas pu s\'ouvrir.');
    case PdfEnregistre() || PdfPartage():
      break; // WhatsApp a pris la main : rien à dire de plus ici.
  }
}

/// Ouvre la quittance du paiement [p] en aperçu (partage, impression).
Future<void> voirQuittance(BuildContext context, WidgetRef ref, Echeance e, Paiement p) async {
  final pdf = await ref.read(loyerRepositoryProvider).quittance(p.id!);
  if (!context.mounted) return;
  pdf.fold(
    (f) => showError(context, f.message),
    (octets) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApercuPdfPage(titre: 'Quittance', nomFichier: nomFichierQuittance(e), pdf: octets),
      ),
    ),
  );
}

/// Juste après un encaissement : proposer d'envoyer la quittance au locataire.
Future<void> proposerQuittance(BuildContext context, WidgetRef ref, Echeance e, Paiement p) =>
    afficherFeuille<void>(context, builder: (ctx) => _PropositionQuittance(echeance: e, paiement: p));

class _PropositionQuittance extends ConsumerStatefulWidget {
  final Echeance echeance;
  final Paiement paiement;

  const _PropositionQuittance({required this.echeance, required this.paiement});

  @override
  ConsumerState<_PropositionQuittance> createState() => _PropositionQuittanceState();
}

class _PropositionQuittanceState extends ConsumerState<_PropositionQuittance> {
  bool _envoi = false;

  Future<void> _envoyer() async {
    setState(() => _envoi = true);
    await envoyerQuittanceWhatsApp(context, ref, widget.echeance, widget.paiement);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.echeance;
    final telephone = e.locataireTelephone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        EnteteFeuille(
          icone: Icons.check_circle_outline_rounded,
          couleur: AppColors.positive,
          titre: 'Paiement de ${formatMontant(widget.paiement.montant)} enregistré',
          sousTitre: '${e.locataireNom} · loyer de ${formatMois(e.periode).toLowerCase()}',
        ),
        const SizedBox(height: 16),
        Text(
          telephone == null || telephone.isEmpty
              ? 'Envoyez la quittance au locataire : WhatsApp s\'ouvrira, quittance jointe, pour choisir le contact.'
              : 'Envoyez la quittance au $telephone : WhatsApp s\'ouvre sur sa conversation, message prêt ; '
                  'joignez la quittance enregistrée avec le trombone.',
          style: TextStyle(fontSize: 13, color: AppColors.label, height: 1.4),
        ),
        const SizedBox(height: 18),
        BoutonPrincipal(
          label: 'Envoyer la quittance par WhatsApp',
          icon: Icons.send_rounded,
          loading: _envoi,
          onPressed: _envoyer,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: BoutonSecondaire(
              label: 'Voir',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: _envoi ? null : () => voirQuittance(context, ref, e, widget.paiement),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BoutonSecondaire(label: 'Plus tard', onPressed: _envoi ? null : () => Navigator.pop(context)),
          ),
        ]),
      ]),
    );
  }
}
