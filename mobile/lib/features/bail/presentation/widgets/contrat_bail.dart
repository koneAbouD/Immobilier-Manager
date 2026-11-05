import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/capture_document.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/bail.dart';
import '../providers/bail_providers.dart';

// ── Actions sur le contrat ──────────────────────────────────────────────────

/// Génère le contrat PDF du bail et l'ouvre en aperçu (partage, impression).
/// Renvoie vrai si la génération a réussi : le bail passe alors « à signer ».
Future<bool> ouvrirContratGenere(BuildContext context, WidgetRef ref, Bail bail) async {
  final result = await ref.read(bailRepositoryProvider).genererContrat(bail.id!);
  if (!context.mounted) return false;
  return result.fold((f) {
    showError(context, f.message);
    return false;
  }, (pdf) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApercuPdfPage(
          titre: 'Contrat à signer',
          nomFichier: 'Contrat-${bail.reference}.pdf',
          pdf: pdf,
        ),
      ),
    );
    return true;
  });
}

/// Ouvre l'exemplaire signé archivé.
Future<void> ouvrirContratSigne(BuildContext context, WidgetRef ref, Bail bail) async {
  final result = await ref.read(bailRepositoryProvider).telechargerContratSigne(bail.id!);
  if (!context.mounted) return;
  result.fold((f) => showError(context, f.message), (contenu) {
    final estPdf = bail.contratSigneType == null || bail.contratSigneType == 'application/pdf';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => estPdf
            ? ApercuPdfPage(
                titre: 'Contrat signé',
                nomFichier: bail.contratSigneNom ?? 'Contrat-signe-${bail.reference}.pdf',
                pdf: contenu)
            : ApercuImagePage(titre: 'Contrat signé', image: contenu),
      ),
    );
  });
}

/// Ouvre l'écran de chargement du contrat signé. Renvoie le bail à jour une
/// fois le fichier archivé, null si l'utilisateur renonce.
Future<Bail?> chargerContratSigne(BuildContext context, WidgetRef ref, Bail bail) async {
  Bail? maj;
  await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => CaptureDocumentPage(
        titre: 'Contrat signé',
        sousTitre: 'Bail ${bail.reference} · ${bail.locataireNom ?? ''}',
        nomFichier: 'Contrat-signe-${bail.reference}.pdf',
        libelleEnvoi: 'Archiver le contrat signé',
        messageSucces: 'Contrat signé archivé.',
        envoyer: (pdf, nom) async {
          final result = await ref
              .read(bailRepositoryProvider)
              .deposerContratSigne(bail.id!, contenu: pdf, nomFichier: nom, type: 'application/pdf');
          return result.fold((f) => f.message, (b) {
            maj = b;
            return null;
          });
        },
      ),
    ),
  );
  return maj;
}

// ── Section « Contrat » d'une fiche bail ────────────────────────────────────

/// Suivi du contrat en trois étapes (généré, en attente de signature, signé)
/// et actions associées.
class SectionContrat extends ConsumerStatefulWidget {
  final Bail bail;

  /// Appelé quand l'état du contrat a changé (généré, signé chargé).
  final VoidCallback onChange;

  const SectionContrat({super.key, required this.bail, required this.onChange});

  @override
  ConsumerState<SectionContrat> createState() => _SectionContratState();
}

class _SectionContratState extends ConsumerState<SectionContrat> {
  bool _generation = false;

  Bail get b => widget.bail;

  Future<void> _generer() async {
    setState(() => _generation = true);
    final ok = await ouvrirContratGenere(context, ref, b);
    if (!mounted) return;
    setState(() => _generation = false);
    if (ok) widget.onChange();
  }

  Future<void> _charger() async {
    final maj = await chargerContratSigne(context, ref, b);
    if (maj != null) widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    final statut = b.statutContrat;
    final signe = statut == StatutContrat.signe;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.history_edu_outlined, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Contrat de bail',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
            ),
            StatutBadgeContrat(statut: statut),
          ]),
          const SizedBox(height: 14),
          _Etape(
            numero: 1,
            titre: 'Contrat généré',
            detail: b.contratGenereLe != null ? 'Le ${formatDate(b.contratGenereLe)}' : null,
            fait: statut != StatutContrat.aGenerer,
            courant: statut == StatutContrat.aGenerer,
          ),
          _Etape(
            numero: 2,
            titre: 'Signature du locataire',
            detail: statut == StatutContrat.aSigner ? 'Imprimez ou partagez le contrat' : null,
            fait: signe,
            courant: statut == StatutContrat.aSigner,
          ),
          _Etape(
            numero: 3,
            titre: 'Contrat signé archivé',
            detail: signe
                ? 'Chargé le ${formatDate(b.contratSigneLe)}'
                    '${b.contratSignePar != null ? ' par ${b.contratSignePar}' : ''}'
                : null,
            fait: signe,
            courant: false,
            dernier: true,
          ),
          const SizedBox(height: 14),
          if (signe) ...[
            _FichierSigne(bail: b, onOuvrir: () => ouvrirContratSigne(context, ref, b)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: BoutonSecondaire(
                  label: 'Remplacer',
                  icon: Icons.upload_file_outlined,
                  onPressed: _charger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BoutonSecondaire(
                  label: 'PDF vierge',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: _generation ? null : _generer,
                ),
              ),
            ]),
          ] else ...[
            BoutonPrincipal(
              label: statut == StatutContrat.aGenerer ? 'Générer le contrat PDF' : 'Revoir le contrat PDF',
              icon: Icons.picture_as_pdf_outlined,
              loading: _generation,
              onPressed: _generer,
            ),
            const SizedBox(height: 10),
            BoutonSecondaire(
              label: 'Charger le contrat signé',
              icon: Icons.document_scanner_outlined,
              onPressed: _charger,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pastille de l'état du contrat.
class StatutBadgeContrat extends StatelessWidget {
  final StatutContrat statut;

  const StatutBadgeContrat({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final couleur = statut.couleur;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(statut.icone, size: 13, color: couleur),
        const SizedBox(width: 4),
        Text(switch (statut) {
          StatutContrat.aGenerer => 'À générer',
          StatutContrat.aSigner => 'À signer',
          StatutContrat.signe => 'Signé',
        }, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
      ]),
    );
  }
}

class _Etape extends StatelessWidget {
  final int numero;
  final String titre;
  final String? detail;
  final bool fait;
  final bool courant;
  final bool dernier;

  const _Etape({
    required this.numero,
    required this.titre,
    this.detail,
    required this.fait,
    required this.courant,
    this.dernier = false,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = fait
        ? AppColors.positive
        : courant
            ? AppColors.warning
            : AppColors.grey400;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: fait || courant ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: fait
                  ? Icon(Icons.check_rounded, size: 15, color: couleur)
                  : Text('$numero',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: couleur)),
            ),
            if (!dernier)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: fait ? AppColors.positive.withValues(alpha: 0.4) : AppColors.grey200,
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3, bottom: dernier ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: courant ? FontWeight.w800 : FontWeight.w600,
                          color: fait || courant ? AppColors.dark : AppColors.grey500)),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(detail!, style: TextStyle(fontSize: 11.5, color: AppColors.label)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FichierSigne extends StatelessWidget {
  final Bail bail;
  final VoidCallback onOuvrir;

  const _FichierSigne({required this.bail, required this.onOuvrir});

  @override
  Widget build(BuildContext context) {
    final taille = bail.contratSigneTaille;
    return Material(
      color: AppColors.blanc,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOuvrir,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bail.contratSigneNom ?? 'Contrat signé',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                if (taille != null)
                  Text(_tailleLisible(taille), style: TextStyle(fontSize: 11.5, color: AppColors.label)),
              ]),
            ),
            Icon(Icons.visibility_outlined, size: 20, color: AppColors.primaryDark),
          ]),
        ),
      ),
    );
  }
}

String _tailleLisible(int octets) => octets < 1024 * 1024
    ? '${(octets / 1024).ceil()} Ko'
    : '${(octets / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';

