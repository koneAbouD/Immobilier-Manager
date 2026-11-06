import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';
import '../providers/loyer_providers.dart';
import '../widgets/encaissement_sheet.dart';

/// Fiche d'un loyer : où il en est (dû, payé, reste), ses paiements
/// (annulables) et l'encaissement du reste. Se ferme en renvoyant vrai si un
/// paiement a été enregistré ou annulé.
class EcheancePage extends ConsumerStatefulWidget {
  final Echeance echeance;

  const EcheancePage({super.key, required this.echeance});

  @override
  ConsumerState<EcheancePage> createState() => _EcheancePageState();
}

class _EcheancePageState extends ConsumerState<EcheancePage> {
  late Echeance _e = widget.echeance;
  late Future<List<Paiement>> _paiements = _chargerPaiements();
  bool _change = false;

  Future<List<Paiement>> _chargerPaiements() async {
    final result = await ref.read(loyerRepositoryProvider).getPaiementsEcheance(_e.id);
    return result.fold((f) => throw f.message, (l) => l);
  }

  /// Recharge le loyer et ses paiements après une action.
  Future<void> _recharger() async {
    final result = await ref.read(loyerRepositoryProvider).getEcheance(_e.id);
    if (!mounted) return;
    setState(() {
      result.fold((_) {}, (e) => _e = e);
      _paiements = _chargerPaiements();
    });
  }

  Future<void> _encaisser() async {
    if (await encaisserEcheance(context, _e)) {
      _change = true;
      _recharger();
    }
  }

  Future<void> _annuler(Paiement p) async {
    final motif = await demanderMotif(context,
        titre: 'Annuler ce paiement de ${formatMontant(p.montant)} ?',
        message: 'Le montant sera de nouveau dû sur ce loyer.',
        action: 'Annuler le paiement');
    if (motif == null || !mounted) return;
    final result = await ref.read(loyerRepositoryProvider).annulerPaiement(p.id!, motif);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Paiement annulé.');
      _change = true;
      _recharger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _change);
      },
      child: Scaffold(
        appBar: AppHeader(
          title: 'Loyer de ${formatMois(e.periode)}',
          backOverride: () => Navigator.pop(context, _change),
        ),
        body: RefreshIndicator(
          onRefresh: _recharger,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _CarteLoyer(echeance: e),
              const SizedBox(height: 14),
              if (e.encaissable)
                BoutonPrincipal(
                  label: 'Encaisser ${formatMontant(e.resteDu)}',
                  icon: Icons.payments_outlined,
                  onPressed: _encaisser,
                ),
              if (e.locataireTelephone != null && e.locataireTelephone!.isNotEmpty) ...[
                const SizedBox(height: 10),
                BoutonSecondaire(
                  label: 'Appeler ${e.locataireNom}',
                  icon: Icons.call_outlined,
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: e.locataireTelephone)),
                ),
              ],
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 10),
                child: Text('Paiements',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark, letterSpacing: -0.3)),
              ),
              FutureBuilder<List<Paiement>>(
                future: _paiements,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return TextButton(
                      onPressed: () => setState(() => _paiements = _chargerPaiements()),
                      child: Text('${snap.error} — Réessayer'),
                    );
                  }
                  if (!snap.hasData) {
                    return const Padding(
                        padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                  }
                  final liste = snap.data!;
                  if (liste.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        Icon(Icons.receipt_long_outlined, color: AppColors.grey400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Aucun paiement pour ce loyer.',
                              style: TextStyle(fontSize: 13, color: AppColors.label)),
                        ),
                      ]),
                    );
                  }
                  return Column(children: [
                    for (final p in liste)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CartePaiement(paiement: p, onAnnuler: () => _annuler(p)),
                      ),
                  ]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête du loyer : locataire et logement, reste dû en grand, barre du payé
/// sur le dû, échéance et retard.
class _CarteLoyer extends StatelessWidget {
  final Echeance echeance;

  const _CarteLoyer({required this.echeance});

  @override
  Widget build(BuildContext context) {
    final e = echeance;
    final couleur = e.enRetard ? AppColors.error : e.statut.couleur;
    final progression = e.montantDu <= 0 ? 0.0 : (e.montantPaye / e.montantDu).clamp(0.0, 1.0);
    final jours = DateUtils.dateOnly(DateTime.now()).difference(DateUtils.dateOnly(e.dateEcheance)).inDays;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: AppColors.cardBorderGradient,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.blanc,
          borderRadius: BorderRadius.circular(AppColors.cardInnerRadius),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.locataireNom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark)),
                const SizedBox(height: 2),
                Text(e.logement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: AppColors.label)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(e.enRetard ? 'En retard' : e.statut.libelle,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: couleur)),
            ),
          ]),
          const SizedBox(height: 18),
          Text(e.encaissable ? 'Reste à payer' : 'Montant du loyer',
              style: TextStyle(fontSize: 12, color: AppColors.label)),
          const SizedBox(height: 2),
          Text(formatMontant(e.encaissable ? e.resteDu : e.montantDu),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: e.enRetard ? AppColors.error : AppColors.dark)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 7,
              color: AppColors.positive,
              backgroundColor: AppColors.grey200,
            ),
          ),
          const SizedBox(height: 6),
          Text('${formatMontant(e.montantPaye)} payés sur ${formatMontant(e.montantDu)}',
              style: TextStyle(fontSize: 12, color: AppColors.label)),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.event_outlined, size: 16, color: AppColors.label),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Échéance le ${formatDate(e.dateEcheance)}',
                  style: TextStyle(fontSize: 12.5, color: AppColors.dark, fontWeight: FontWeight.w600)),
            ),
            if (e.enRetard && jours > 0)
              Text('$jours j de retard',
                  style: TextStyle(fontSize: 12.5, color: AppColors.error, fontWeight: FontWeight.w700)),
          ]),
          if (e.bailReference != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.description_outlined, size: 16, color: AppColors.label),
              const SizedBox(width: 6),
              Text('Bail ${e.bailReference}', style: TextStyle(fontSize: 12.5, color: AppColors.label)),
            ]),
          ],
        ]),
      ),
    );
  }
}

/// Un paiement : montant, date et mode, auteur ; barré s'il est annulé.
class _CartePaiement extends StatelessWidget {
  final Paiement paiement;
  final VoidCallback onAnnuler;

  const _CartePaiement({required this.paiement, required this.onAnnuler});

  IconData get _icone => switch (paiement.modePaiement) {
        ModePaiement.especes => Icons.payments_outlined,
        ModePaiement.mobileMoney => Icons.phone_android_rounded,
        ModePaiement.virement => Icons.account_balance_outlined,
        ModePaiement.cheque => Icons.edit_note_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = paiement;
    final couleur = p.annule ? AppColors.hint : AppColors.positive;
    final barre = p.annule ? TextDecoration.lineThrough : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(p.annule ? Icons.block_rounded : _icone, size: 18, color: couleur),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(formatMontant(p.montant),
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dark, decoration: barre)),
              ),
              if (!p.annule)
                InkWell(
                  onTap: onAnnuler,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text('Annuler',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ),
                ),
            ]),
            const SizedBox(height: 3),
            Text(
              '${formatDate(p.datePaiement)} · ${p.modePaiement.libelle}'
              '${p.reference != null ? ' · ${p.reference}' : ''}',
              style: TextStyle(fontSize: 12, color: AppColors.label),
            ),
            const SizedBox(height: 2),
            Text(
              p.annule
                  ? 'Annulé par ${p.annulePar ?? '—'} : ${p.motifAnnulation ?? ''}'
                  : 'Encaissé par ${p.encaissePar ?? '—'}',
              style: TextStyle(fontSize: 11.5, color: p.annule ? AppColors.error : AppColors.grey500),
            ),
          ]),
        ),
      ]),
    );
  }
}
