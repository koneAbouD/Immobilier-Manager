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
import '../widgets/encaissement_sheet.dart';

/// Onglet « Loyers » : échéances à encaisser et journal des paiements. Le
/// sous-onglet est choisi par les pastilles de l'en-tête (HomeScreen).
class LoyersPage extends StatelessWidget {
  /// 0 = Échéances, 1 = Paiements.
  final int onglet;

  const LoyersPage({super.key, this.onglet = 0});

  @override
  Widget build(BuildContext context) => onglet == 0 ? const _EcheancesTab() : const _PaiementsTab();
}

/// Filtre rapide des échéances.
enum _FiltreEcheance { aEncaisser, enRetard, payees, toutes }

class _EcheancesTab extends ConsumerStatefulWidget {
  const _EcheancesTab();

  @override
  ConsumerState<_EcheancesTab> createState() => _EcheancesTabState();
}

class _EcheancesTabState extends ConsumerState<_EcheancesTab> {
  final _listKey = GlobalKey<PagedListViewState<Echeance>>();
  _FiltreEcheance _filtre = _FiltreEcheance.aEncaisser;
  DateTime? _mois = DateTime(DateTime.now().year, DateTime.now().month);

  void _changerMois(int delta) =>
      setState(() => _mois = DateTime(_mois!.year, _mois!.month + delta));

  Future<void> _choisirMois() async {
    final m = _mois ?? DateTime.now();
    final choisi = await showDialog<DateTime>(
      context: context,
      builder: (_) => MonthPickerDialog(initialYear: m.year, initialMonth: m.month),
    );
    if (choisi != null && mounted) setState(() => _mois = DateTime(choisi.year, choisi.month));
  }

  Future<void> _generer() async {
    final result = await ref.read(loyerRepositoryProvider).genererEcheances();
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (n) {
      showSuccess(context, n == 0 ? 'Tous les loyers sont déjà émis.' : '$n loyer(s) émis.');
      _listKey.currentState?.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(loyerRepositoryProvider);
    // Le retard porte sur tous les mois passés : le filtre de mois ne s'y applique pas.
    final periode = _filtre == _FiltreEcheance.enRetard ? null : _mois;
    final statut = switch (_filtre) {
      _FiltreEcheance.payees => StatutEcheance.payee,
      _ => null,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              _BoutonCarre(
                icon: Icons.chevron_left_rounded,
                onTap: periode == null ? null : () => _changerMois(-1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PastilleMois(
                  libelle: periode == null ? 'Tous les mois' : formatMois(periode),
                  onTap: periode == null ? null : _choisirMois,
                ),
              ),
              const SizedBox(width: 8),
              _BoutonCarre(
                icon: Icons.chevron_right_rounded,
                onTap: periode == null ? null : () => _changerMois(1),
              ),
              const SizedBox(width: 8),
              _BoutonCarre(
                icon: Icons.playlist_add_rounded,
                tooltip: 'Émettre les loyers manquants',
                onTap: _generer,
              ),
            ],
          ),
        ),
        FiltresStatut<_FiltreEcheance>(
          options: _FiltreEcheance.values,
          selection: _filtre,
          libelle: (f) => switch (f) {
            _FiltreEcheance.aEncaisser => 'À encaisser',
            _FiltreEcheance.enRetard => 'En retard',
            _FiltreEcheance.payees => 'Payées',
            _FiltreEcheance.toutes => 'Toutes',
          },
          onSelected: (f) => setState(() => _filtre = f),
        ),
        Expanded(
          child: PagedListView<Echeance>(
            key: _listKey,
            filtresKey: (_filtre, periode),
            fetcher: (page, size) => repo.getEcheances(
              page: page,
              size: size,
              periode: periode,
              statut: statut,
              aEncaisser: _filtre == _FiltreEcheance.aEncaisser,
              enRetard: _filtre == _FiltreEcheance.enRetard,
            ),
            emptyIcon: Icons.receipt_long_outlined,
            emptyMessage: 'Aucune échéance pour ce filtre.',
            itemBuilder: (context, e) => EcheanceTile(
              echeance: e,
              onTap: () async {
                if (await ouvrirEcheance(context, e)) _listKey.currentState?.refresh();
              },
            ),
          ),
        ),
      ],
    );
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

  const _BoutonCarre({required this.icon, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final bouton = Material(
      color: AppColors.blanc,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: onTap == null ? AppColors.grey300 : AppColors.grey600),
        ),
      ),
    );
    return tooltip == null ? bouton : Tooltip(message: tooltip!, child: bouton);
  }
}
