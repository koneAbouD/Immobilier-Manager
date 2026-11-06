import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/date_filter_dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/statut_filtre_chip.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';
import '../providers/loyer_providers.dart';
import '../widgets/echeance_tile.dart';
import '../../../tableau_bord/domain/entities/tableau_bord.dart';
import '../../../tableau_bord/presentation/providers/tableau_bord_providers.dart';
import '../widgets/creation_loyers_sheet.dart';
import '../widgets/encaissement_sheet.dart';

/// Onglet « Loyers » : loyers émis par mois et journal des paiements. Le
/// sous-onglet est choisi par les pastilles de l'en-tête (HomeScreen).
class LoyersPage extends StatelessWidget {
  /// 0 = Échéances, 1 = Paiements.
  final int onglet;

  const LoyersPage({super.key, this.onglet = 0});

  @override
  Widget build(BuildContext context) => onglet == 0 ? const _EcheancesTab() : const _PaiementsTab();
}

/// Filtre rapide des loyers.
enum _FiltreEcheance { tous, aEncaisser, enRetard, payes }

/// Résumé des loyers d'un mois (attendu, encaissé, taux), lu dans le tableau de bord.
final _resumeMoisProvider = FutureProvider.autoDispose.family<TableauBord, DateTime>((ref, mois) async {
  final result = await ref.watch(tableauBordRepositoryProvider).get(periode: mois);
  return result.fold((f) => throw f.message, (t) => t);
});

/// Loyers émis, mois par mois : résumé du mois, filtres, puis la liste. Un
/// loyer s'ouvre sur sa fiche (paiements, encaissement). Le loyer du mois en
/// cours n'est émis automatiquement qu'à partir du 25 ; les mois suivants se
/// créent à la main.
class _EcheancesTab extends ConsumerStatefulWidget {
  const _EcheancesTab();

  @override
  ConsumerState<_EcheancesTab> createState() => _EcheancesTabState();
}

class _EcheancesTabState extends ConsumerState<_EcheancesTab> {
  final _listKey = GlobalKey<PagedListViewState<Echeance>>();
  _FiltreEcheance _filtre = _FiltreEcheance.tous;
  DateTime _mois = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get _moisCourant => DateTime(DateTime.now().year, DateTime.now().month);

  void _changerMois(int delta) => setState(() => _mois = DateTime(_mois.year, _mois.month + delta));

  Future<void> _choisirMois() async {
    final choisi = await showDialog<DateTime>(
      context: context,
      builder: (_) => MonthPickerDialog(initialYear: _mois.year, initialMonth: _mois.month),
    );
    if (choisi != null && mounted) setState(() => _mois = DateTime(choisi.year, choisi.month));
  }

  void _rafraichir() {
    _listKey.currentState?.refresh();
    ref.invalidate(_resumeMoisProvider(_mois));
  }

  Future<void> _creer({DateTime? mois}) async {
    final n = await creerLoyers(context, mois: mois);
    if (n != null && mounted) _rafraichir();
  }

  /// Émet tout de suite les loyers du mois en cours, sans attendre le 25.
  Future<void> _emettreMaintenant() async {
    final result = await ref.read(loyerRepositoryProvider).genererEcheances(jusquA: _mois);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (n) {
      showSuccess(context, n == 0 ? 'Les loyers du mois sont déjà émis.' : '$n loyer(s) émis.');
      _rafraichir();
    });
  }

  /// Message et action de la liste vide, selon que le mois est passé, en
  /// cours (avant le 25) ou à venir.
  (String, String?, VoidCallback?) get _vide {
    if (_filtre != _FiltreEcheance.tous) return ('Aucun loyer pour ce filtre.', null, null);
    final mois = formatMois(_mois).toLowerCase();
    if (_mois == _moisCourant && DateTime.now().day < kJourEmissionLoyers) {
      return (
        'Les loyers de $mois seront émis automatiquement le $kJourEmissionLoyers.',
        'Les émettre maintenant',
        _emettreMaintenant,
      );
    }
    if (_mois.isAfter(_moisCourant)) {
      return ('Les loyers de $mois ne sont pas encore créés.', 'Créer les loyers de $mois', () => _creer(mois: _mois));
    }
    return ('Aucun loyer pour $mois.', null, null);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(loyerRepositoryProvider);
    // Le retard porte sur tous les mois passés : le filtre de mois ne s'y applique pas.
    final parMois = _filtre != _FiltreEcheance.enRetard;
    final vide = _vide;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              _BoutonCarre(icon: Icons.chevron_left_rounded, onTap: parMois ? () => _changerMois(-1) : null),
              const SizedBox(width: 8),
              Expanded(
                child: _PastilleMois(
                  libelle: parMois ? formatMois(_mois) : 'Tous les mois',
                  onTap: parMois ? _choisirMois : null,
                ),
              ),
              const SizedBox(width: 8),
              _BoutonCarre(icon: Icons.chevron_right_rounded, onTap: parMois ? () => _changerMois(1) : null),
              const SizedBox(width: 8),
              _BoutonCarre(icon: Icons.add_rounded, tooltip: 'Créer des loyers', onTap: _creer, accent: true),
            ],
          ),
        ),
        if (parMois)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ResumeMois(mois: _mois, async: ref.watch(_resumeMoisProvider(_mois))),
          ),
        FiltresStatut<_FiltreEcheance>(
          options: _FiltreEcheance.values,
          selection: _filtre,
          libelle: (f) => switch (f) {
            _FiltreEcheance.tous => 'Tous',
            _FiltreEcheance.aEncaisser => 'À encaisser',
            _FiltreEcheance.enRetard => 'En retard',
            _FiltreEcheance.payes => 'Payés',
          },
          onSelected: (f) => setState(() => _filtre = f),
        ),
        Expanded(
          child: PagedListView<Echeance>(
            key: _listKey,
            filtresKey: (_filtre, _mois),
            fetcher: (page, size) => repo.getEcheances(
              page: page,
              size: size,
              periode: parMois ? _mois : null,
              statut: _filtre == _FiltreEcheance.payes ? StatutEcheance.payee : null,
              aEncaisser: _filtre == _FiltreEcheance.aEncaisser,
              enRetard: _filtre == _FiltreEcheance.enRetard,
            ),
            emptyIcon: Icons.event_note_outlined,
            emptyMessage: vide.$1,
            emptyActionLabel: vide.$2,
            onEmptyAction: vide.$3,
            itemBuilder: (context, e) => EcheanceTile(
              echeance: e,
              onTap: () async {
                if (await ouvrirEcheance(context, e)) _rafraichir();
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Résumé du mois : encaissé sur attendu, barre de recouvrement, reste.
class _ResumeMois extends StatelessWidget {
  final DateTime mois;
  final AsyncValue<TableauBord> async;

  const _ResumeMois({required this.mois, required this.async});

  @override
  Widget build(BuildContext context) {
    final t = async.valueOrNull;
    final attendus = t?.loyersAttendus ?? 0;
    final encaisses = t?.loyersEncaisses ?? 0;
    final taux = attendus <= 0 ? 0.0 : (encaisses / attendus).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.cardTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: _Chiffre(libelle: 'Encaissé', valeur: t == null ? '…' : formatMontant(encaisses), fort: true),
          ),
          _Chiffre(libelle: 'Attendu', valeur: t == null ? '…' : formatMontant(attendus), aDroite: true),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: taux,
            minHeight: 6,
            color: AppColors.positive,
            backgroundColor: AppColors.grey200,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t == null
              ? ' '
              : attendus <= 0
                  ? 'Aucun loyer émis pour ce mois'
                  : '${(taux * 100).round()} % recouvré · reste ${formatMontant(t.resteAEncaisser)}',
          style: TextStyle(fontSize: 11.5, color: AppColors.label),
        ),
      ]),
    );
  }
}

class _Chiffre extends StatelessWidget {
  final String libelle;
  final String valeur;
  final bool fort;
  final bool aDroite;

  const _Chiffre({required this.libelle, required this.valeur, this.fort = false, this.aDroite = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: aDroite ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Text(libelle, style: TextStyle(fontSize: 11.5, color: AppColors.label)),
      const SizedBox(height: 1),
      Text(valeur,
          style: TextStyle(
              fontSize: fort ? 18 : 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
              letterSpacing: fort ? -0.4 : 0)),
    ]);
  }
}

class _PaiementsTab extends ConsumerWidget {
  const _PaiementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(loyerRepositoryProvider);
    return PagedListView<Paiement>(
      fetcher: (page, size) => repo.getPaiements(page: page, size: size),
      emptyIcon: Icons.payments_outlined,
      emptyMessage: 'Aucun paiement enregistré.',
      itemBuilder: (context, p) => ListeCarte(
        icon: p.annule ? Icons.block_rounded : Icons.trending_up_rounded,
        couleur: p.annule ? AppColors.hint : AppColors.positive,
        titre: p.locataireNom ?? '',
        valeur: formatMontant(p.montant),
        barre: p.annule,
        sousTitre: '${formatMois(p.periode)} · ${p.appartementReference ?? ''}',
        detail: '${formatDate(p.datePaiement)} · ${p.modePaiement.libelle}',
        badge: p.annule ? PastilleStatut('Annulé', AppColors.error) : null,
      ),
    );
  }
}

/// Pastille du mois affiché, au style du filtre par mois de VTC Manager.
class _PastilleMois extends StatelessWidget {
  final String libelle;

  /// Ouvre la molette des mois.
  final VoidCallback? onTap;

  const _PastilleMois({required this.libelle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.grey600),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                libelle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit bouton carré blanc bordé de gris (mois précédent/suivant, émission).
class _BoutonCarre extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  /// Plein, à la couleur d'accent (action principale de la barre).
  final bool accent;

  const _BoutonCarre({required this.icon, this.onTap, this.tooltip, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final bouton = Material(
      color: accent ? AppColors.primary : AppColors.blanc,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: accent ? AppColors.primary : AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon,
              size: 20,
              color: accent
                  ? AppColors.onPrimary
                  : onTap == null
                      ? AppColors.grey300
                      : AppColors.grey600),
        ),
      ),
    );
    return tooltip == null ? bouton : Tooltip(message: tooltip!, child: bouton);
  }
}
