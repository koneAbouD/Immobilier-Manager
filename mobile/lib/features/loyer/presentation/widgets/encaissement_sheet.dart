import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';
import '../providers/loyer_providers.dart';

/// Fiche d'une échéance : paiements reçus (annulables) et encaissement du
/// reste dû. Renvoie vrai si quelque chose a changé.
Future<bool> ouvrirEcheance(BuildContext context, Echeance echeance) async {
  final change = await afficherFeuille<bool>(
    context,
    builder: (_) => _EcheanceSheet(echeance: echeance),
  );
  return change ?? false;
}

class _EcheanceSheet extends ConsumerStatefulWidget {
  final Echeance echeance;

  const _EcheanceSheet({required this.echeance});

  @override
  ConsumerState<_EcheanceSheet> createState() => _EcheanceSheetState();
}

class _EcheanceSheetState extends ConsumerState<_EcheanceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _montant =
      TextEditingController(text: widget.echeance.resteDu.toStringAsFixed(0));
  final _reference = TextEditingController();
  ModePaiement _mode = ModePaiement.especes;
  DateTime? _date = DateTime.now();
  bool _envoi = false;
  late Future<List<Paiement>> _paiements = _chargerPaiements();

  Echeance get e => widget.echeance;

  Future<List<Paiement>> _chargerPaiements() async {
    final result = await ref.read(loyerRepositoryProvider).getPaiementsEcheance(e.id);
    return result.fold((f) => throw f.message, (l) => l);
  }

  @override
  void dispose() {
    _montant.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _encaisser() async {
    if (!_formKey.currentState!.validate()) return;
    final montant = parseMontantSaisi(_montant.text)!;
    if (montant > e.resteDu) {
      showError(context, 'Le montant dépasse le reste dû (${formatMontant(e.resteDu)}).');
      return;
    }
    setState(() => _envoi = true);
    final result = await ref.read(loyerRepositoryProvider).encaisser(
          e.id,
          Paiement(
            montant: montant,
            datePaiement: _date,
            modePaiement: _mode,
            reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Paiement de ${formatMontant(montant)} enregistré.');
      Navigator.pop(context, true);
    });
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
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnteteFeuille(
              icone: Icons.receipt_long_outlined,
              couleur: e.enRetard ? AppColors.error : null,
              titre: 'Loyer de ${formatMois(e.periode)}',
              sousTitre: '${e.locataireNom} · ${e.logement}',
              trailing: StatutBadge(e.enRetard ? 'En retard' : e.statut.libelle,
                  e.enRetard ? AppColors.error : e.statut.couleur),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: AppColors.cardTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                LigneInfo('Montant dû', formatMontant(e.montantDu)),
                LigneInfo('Déjà payé', formatMontant(e.montantPaye)),
                LigneInfo('Échéance', formatDate(e.dateEcheance)),
                Divider(height: 12, color: AppColors.border),
                LigneInfo('Reste dû', formatMontant(e.resteDu), fort: true),
              ]),
            ),
            const SizedBox(height: 8),
            const SectionTitre('Paiements reçus'),
            FutureBuilder<List<Paiement>>(
              future: _paiements,
              builder: (context, snap) {
                if (snap.hasError) {
                  return TextButton(
                    onPressed: () => setState(() => _paiements = _chargerPaiements()),
                    child: Text('${snap.error} — Réessayer'),
                  );
                }
                if (!snap.hasData) return const LinearProgressIndicator();
                if (snap.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Aucun paiement.', style: TextStyle(color: AppColors.grey500)),
                  );
                }
                return Column(
                  children: snap.data!
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListeCarte(
                              icon: p.annule ? Icons.block_rounded : Icons.trending_up_rounded,
                              couleur: p.annule ? AppColors.hint : AppColors.positive,
                              titre: formatMontant(p.montant),
                              barre: p.annule,
                              sousTitre: p.annule
                                  ? 'Annulé par ${p.annulePar ?? '—'} : ${p.motifAnnulation ?? ''}'
                                  : '${formatDate(p.datePaiement)} · ${p.modePaiement.libelle}'
                                      '${p.reference != null ? ' · ${p.reference}' : ''}',
                              detail: p.annule ? null : 'Encaissé par ${p.encaissePar ?? '—'}',
                              badge: p.annule
                                  ? null
                                  : InkWell(
                                      onTap: () => _annuler(p),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Text('Annuler',
                                            style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.error)),
                                      ),
                                    ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            if (e.encaissable) ...[
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitre('Encaisser'),
                    ChampMontant(
                        controller: _montant, label: 'Montant', obligatoire: true, strictementPositif: true),
                    kGapChamps,
                    ChampChoix<ModePaiement>(
                      label: 'Mode de paiement',
                      valeur: _mode,
                      options: ModePaiement.values,
                      libelle: (m) => m.libelle,
                      onChanged: (m) => setState(() => _mode = m ?? ModePaiement.especes),
                    ),
                    kGapChamps,
                    ChampDate(
                      label: 'Date du paiement',
                      valeur: _date,
                      obligatoire: true,
                      derniere: DateTime.now(),
                      onChanged: (d) => setState(() => _date = d),
                    ),
                    kGapChamps,
                    ChampTexte(controller: _reference, label: 'Référence', hint: 'N° de transaction ou de chèque'),
                    const SizedBox(height: 16),
                    BoutonPrincipal(
                      label: 'Enregistrer le paiement',
                      icon: Icons.payments_outlined,
                      loading: _envoi,
                      onPressed: _encaisser,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
