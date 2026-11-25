import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/bail.dart';
import '../providers/bail_providers.dart';
import '../widgets/champs_bail.dart';
import '../../../../core/utils/insets_systeme.dart';
import '../../../../core/widgets/libelle_bouton.dart';
import '../../../../core/utils/separateur_milliers.dart';

/// Révision des conditions d'un bail actif. Le logement et le locataire ne
/// changent pas ; les loyers déjà émis gardent leur montant.
///
/// Premier loyer facturé : recalculé par le serveur si la date de début ou
/// l'avance change tant qu'aucun loyer n'est émis, ou choisi à la main.
class BailModifierPage extends ConsumerStatefulWidget {
  final Bail bail;

  const BailModifierPage({super.key, required this.bail});

  @override
  ConsumerState<BailModifierPage> createState() => _BailModifierPageState();
}

class _BailModifierPageState extends ConsumerState<BailModifierPage> {
  final _formKey = GlobalKey<FormState>();
  late final Bail b = widget.bail;
  late DateTime _dateDebut = b.dateDebut;
  late DateTime? _dateFin = b.dateFin;
  late bool _dureeIndeterminee = b.dateFin == null;
  late final _loyer = TextEditingController(text: saisieMontant(b.loyerMensuel));
  late final _charges = TextEditingController(text: saisieMontant(b.charges ?? 0));
  late final _moisCaution = TextEditingController(text: b.moisCaution?.toString() ?? '');
  late final _moisAvance = TextEditingController(text: '${b.moisAvance ?? 0}');
  late final _jour = TextEditingController(text: '${b.jourEcheance ?? 5}');
  late final UsageBail _usageInitial = b.usage ?? UsageBail.habitation;
  late UsageBail _usage = _usageInitial;
  late bool _externe = b.externe;
  late final _gestionnaireExterne = TextEditingController(text: b.gestionnaireExterne ?? '');

  /// Premier mois choisi à la main ; nul tant qu'il suit le calcul.
  DateTime? _premierChoisi;
  bool _envoi = false;

  @override
  void dispose() {
    for (final c in [_loyer, _charges, _moisCaution, _moisAvance, _jour, _gestionnaireExterne]) {
      c.dispose();
    }
    super.dispose();
  }

  static DateTime _mois(DateTime d) => DateTime(d.year, d.month);

  int get _avance => int.tryParse(_moisAvance.text) ?? 0;

  bool get _debutOuAvanceModifie => _dateDebut != b.dateDebut || _avance != (b.moisAvance ?? 0);

  /// Premier mois affiché : le choix manuel, sinon le recalcul si la date de
  /// début ou l'avance a changé, sinon la valeur actuelle.
  DateTime? get _premierAffiche {
    if (_premierChoisi != null) return _premierChoisi;
    if (_debutOuAvanceModifie) {
      return Bail.calculerPremierMoisFacture(_dateDebut, _avance, b.creeLe ?? DateTime.now());
    }
    return b.premierMoisFacture == null ? null : _mois(b.premierMoisFacture!);
  }

  /// Mois proposés : du mois de début à deux ans après aujourd'hui (ou après
  /// le premier mois actuel s'il est plus lointain).
  List<DateTime> get _moisPossibles {
    final debut = _mois(_dateDebut);
    var fin = DateTime(DateTime.now().year, DateTime.now().month + 24);
    final actuel = _premierAffiche;
    if (actuel != null && actuel.isAfter(fin)) fin = actuel;
    return [for (var m = debut; !m.isAfter(fin); m = DateTime(m.year, m.month + 1)) m];
  }

  String? _validerMois(String? v, {bool obligatoire = true}) {
    if ((v == null || v.trim().isEmpty) && !obligatoire) return null;
    final m = int.tryParse(v ?? '');
    return m == null || m < 0 || m > 24 ? 'Entre 0 et 24.' : null;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_dureeIndeterminee && _dateFin != null && !_dateFin!.isAfter(_dateDebut)) {
      showError(context, 'La date de fin doit être postérieure à la date de début.');
      return;
    }
    setState(() => _envoi = true);
    final caution = int.tryParse(_moisCaution.text);
    final modifications = Bail(
      appartementId: b.appartementId,
      locataireId: b.locataireId,
      // Envoyé seulement s'il change.
      usage: _usage != _usageInitial ? _usage : null,
      dateDebut: _dateDebut,
      dateFin: _dureeIndeterminee ? null : _dateFin,
      loyerMensuel: parseMontantSaisi(_loyer.text),
      charges: parseMontantSaisi(_charges.text) ?? 0,
      // Envoyé seulement s'il change : une révision du loyer ne recalcule pas
      // la caution déjà versée.
      moisCaution: caution != b.moisCaution ? caution : null,
      moisAvance: _avance,
      premierMoisFacture: _premierChoisi,
      jourEcheance: int.tryParse(_jour.text),
      externe: _externe,
      gestionnaireExterne: _externe && _gestionnaireExterne.text.trim().isNotEmpty
          ? _gestionnaireExterne.text.trim()
          : null,
    );
    if (_externe && !b.externe && !await _confirmerPassageExterne()) {
      setState(() => _envoi = false);
      return;
    }
    final result = await ref.read(bailRepositoryProvider).update(b.id!, modifications);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (maj) {
      showSuccess(context, 'Bail modifié.');
      Navigator.pop(context, maj);
    });
  }

  /// Passer externe annule les loyers déjà émis et non réglés : on prévient.
  Future<bool> _confirmerPassageExterne() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Passer le bail en externe ?'),
        content: const Text(
          'Les loyers déjà émis pour ce bail seront annulés et plus aucun ne sera généré. '
          'Impossible si un loyer a déjà été encaissé.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const LibelleBouton('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const LibelleBouton('Confirmer')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final modifiable = b.recouvrementModifiable();
    return Scaffold(
      appBar: AppHeader(title: 'Modifier le bail'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + context.basSysteme),
          children: [
            _Avertissement(bail: b),
            const SizedBox(height: 12),
            GroupeChamps(
              titre: 'Type de bail',
              icone: Icons.gavel_rounded,
              couleur: AppColors.primary,
              children: [
                ChoixUsageBail(valeur: _usage, onChanged: (u) => setState(() => _usage = u)),
                if (_usage != _usageInitial && b.statutContrat != StatutContrat.aGenerer)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Le contrat déjà généré suit l\'ancien type : générez-le à nouveau.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
              ],
            ),
            GroupeChamps(
              titre: 'Durée',
              icone: Icons.event_outlined,
              couleur: AppColors.info,
              children: [
                InterrupteurDuree(
                  valeur: _dureeIndeterminee,
                  onChanged: (v) => setState(() {
                    _dureeIndeterminee = v;
                    if (v) _dateFin = null;
                  }),
                ),
                kGapChamps,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ChampDate(
                        label: 'Début',
                        valeur: _dateDebut,
                        obligatoire: true,
                        onChanged: (d) => setState(() {
                          if (d != null) _dateDebut = d;
                          // Un choix antérieur au nouveau début n'est plus valable.
                          if (_premierChoisi != null && _premierChoisi!.isBefore(_mois(_dateDebut))) {
                            _premierChoisi = null;
                          }
                        }),
                      ),
                    ),
                    if (!_dureeIndeterminee) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChampDate(
                          label: 'Fin',
                          valeur: _dateFin,
                          premiere: _dateDebut,
                          onChanged: (d) => setState(() => _dateFin = d),
                        ),
                      ),
                    ],
                  ],
                ),
                kGapChamps,
                ChampEntier(
                  controller: _jour,
                  label: 'Jour d\'échéance du loyer',
                  hint: '5',
                  obligatoire: true,
                  aide: 'Jour du mois où le loyer est exigible (1 à 28)',
                  validator: (v) {
                    final j = int.tryParse(v ?? '');
                    return j == null || j < 1 || j > 28 ? 'Entre 1 et 28.' : null;
                  },
                ),
              ],
            ),
            GroupeChamps(
              titre: 'Montants',
              icone: Icons.payments_outlined,
              couleur: AppColors.positive,
              children: [
                ChampMontant(controller: _loyer, label: 'Loyer mensuel', obligatoire: true, strictementPositif: true),
                kGapChamps,
                ChampMontant(controller: _charges, label: 'Charges mensuelles'),
                kGapChamps,
                ChampEntier(
                  controller: _moisCaution,
                  label: 'Mois de caution',
                  hint: b.moisCaution == null ? 'Montant libre' : '2',
                  aide: 'Modifié, le dépôt de garantie est recalculé sur le loyer (0 à 24)',
                  validator: (v) => _validerMois(v, obligatoire: false),
                ),
                kGapChamps,
                ListenableBuilder(
                  listenable: Listenable.merge([_loyer, _moisCaution]),
                  builder: (context, _) {
                    final mois = int.tryParse(_moisCaution.text);
                    final loyer = parseMontantSaisi(_loyer.text);
                    // La caution n'est recalculée que si le nombre de mois change.
                    final montant = mois != null && mois != b.moisCaution && loyer != null
                        ? loyer * mois
                        : b.depotGarantie;
                    return DepotCalcule(montant: montant, mois: mois ?? b.moisCaution);
                  },
                ),
              ],
            ),
            GroupeChamps(
              titre: 'Recouvrement',
              icone: Icons.account_balance_wallet_outlined,
              couleur: AppColors.warning,
              children: [
                InterrupteurBailExterne(
                  valeur: _externe,
                  onChanged: modifiable ? (v) => setState(() => _externe = v) : null,
                  detail: modifiable
                      ? null
                      : 'Modifiable dans les ${Bail.delaiChangementRecouvrementJours} jours suivant la création '
                            '(jusqu\'au ${formatDate(b.limiteChangementRecouvrement)})',
                ),
                if (_externe) ...[
                  kGapChamps,
                  ChampTexte(
                    controller: _gestionnaireExterne,
                    label: 'Entité de recouvrement',
                    hint: 'Agence, mandataire…',
                    validator: (v) => (v ?? '').trim().length > 150 ? '150 caractères au plus.' : null,
                  ),
                ] else if (modifiable)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Modifiable jusqu\'au ${formatDate(b.limiteChangementRecouvrement)}',
                      style: TextStyle(fontSize: 12, color: AppColors.label),
                    ),
                  ),
              ],
            ),
            if (!_externe)
              GroupeChamps(
                titre: 'Facturation',
                icone: Icons.event_available_outlined,
                couleur: AppColors.warning,
                children: [
                  ChampEntier(
                    controller: _moisAvance,
                    label: 'Mois d\'avance',
                    hint: '0',
                    obligatoire: true,
                    aide: 'Loyers réglés à la signature, non restitués : ces mois ne sont pas facturés (0 à 24)',
                    validator: _validerMois,
                  ),
                  kGapChamps,
                  ListenableBuilder(
                    listenable: Listenable.merge([_loyer, _charges, _moisAvance]),
                    builder: (context, _) {
                      final mensuel = (parseMontantSaisi(_loyer.text) ?? 0) + (parseMontantSaisi(_charges.text) ?? 0);
                      return ChampChoix<DateTime>(
                        label: 'Premier loyer facturé',
                        valeur: _premierAffiche,
                        options: _moisPossibles,
                        libelle: formatMois,
                        onChanged: (m) => setState(() => _premierChoisi = m),
                      ).avecApercu(
                        PremierLoyer(
                          titre: _premierChoisi != null
                              ? 'Choisi à la main'
                              : _debutOuAvanceModifie
                              ? 'Recalculé si aucun loyer n\'est encore émis'
                              : 'Premier loyer facturé',
                          premierMois: _premierAffiche,
                          moisAvance: _avance,
                          montantAvance: mensuel * _avance,
                        ),
                      );
                    },
                  ),
                  if (_premierChoisi != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _premierChoisi = null),
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const LibelleBouton('Revenir au calcul automatique'),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            BoutonPrincipal(label: 'Enregistrer', loading: _envoi, onPressed: _enregistrer),
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  /// Le champ, suivi de son aperçu.
  Widget avecApercu(Widget apercu) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [this, kGapChamps, apercu]);
}

/// Rappel de ce que la modification touche — et de ce qu'elle ne touche pas.
class _Avertissement extends StatelessWidget {
  final Bail bail;

  const _Avertissement({required this.bail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${bail.locataireNom ?? ''} · ${bail.logement}\n'
              'Les loyers déjà émis gardent leur montant : les nouvelles conditions '
              's\'appliquent aux suivants.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.label),
            ),
          ),
        ],
      ),
    );
  }
}
