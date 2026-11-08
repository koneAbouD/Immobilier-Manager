import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';
import '../pages/echeance_page.dart';
import '../providers/loyer_providers.dart';

/// Ouvre la fiche d'un loyer : ses paiements et l'encaissement du reste dû.
/// Renvoie vrai si quelque chose a changé (paiement enregistré ou annulé).
Future<bool> ouvrirEcheance(BuildContext context, Echeance echeance) async {
  final change = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => EcheancePage(echeance: echeance)),
  );
  return change ?? false;
}

/// Formulaire d'encaissement en feuille du bas. Renvoie le paiement
/// enregistré, ou null si l'utilisateur renonce.
Future<Paiement?> encaisserEcheance(BuildContext context, Echeance echeance) => afficherFeuille<Paiement>(
      context,
      builder: (_) => _FormulaireEncaissement(echeance: echeance),
    );

class _FormulaireEncaissement extends ConsumerStatefulWidget {
  final Echeance echeance;

  const _FormulaireEncaissement({required this.echeance});

  @override
  ConsumerState<_FormulaireEncaissement> createState() => _FormulaireEncaissementState();
}

class _FormulaireEncaissementState extends ConsumerState<_FormulaireEncaissement> {
  final _formKey = GlobalKey<FormState>();
  late final _montant = TextEditingController(text: widget.echeance.resteDu.toStringAsFixed(0));
  final _reference = TextEditingController();
  ModePaiement _mode = ModePaiement.especes;
  DateTime? _date = DateTime.now();
  bool _envoi = false;

  Echeance get e => widget.echeance;

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
    result.fold((f) => showError(context, f.message), (paiement) {
      showSuccess(context, 'Paiement de ${formatMontant(montant)} enregistré.');
      Navigator.pop(context, paiement);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnteteFeuille(
                icone: Icons.payments_outlined,
                titre: 'Encaisser',
                sousTitre: '${e.locataireNom} · reste ${formatMontant(e.resteDu)}',
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 20),
              BoutonPrincipal(
                label: 'Enregistrer le paiement',
                icon: Icons.check_rounded,
                loading: _envoi,
                onPressed: _encaisser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
