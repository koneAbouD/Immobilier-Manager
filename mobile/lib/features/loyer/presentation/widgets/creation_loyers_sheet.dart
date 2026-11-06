import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/date_filter_dialogs.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/selection_page.dart';
import '../../../bail/domain/entities/bail.dart';
import '../../../bail/presentation/providers/bail_providers.dart';
import '../providers/loyer_providers.dart';

/// Le loyer d'un mois n'est émis automatiquement qu'à partir de ce jour du mois.
const kJourEmissionLoyers = 25;

/// Ouvre la feuille de création manuelle des loyers : un mois (le suivant par
/// défaut) et la portée (tous les baux actifs ou un bail). Renvoie le nombre
/// de loyers créés, ou null si l'utilisateur renonce.
Future<int?> creerLoyers(BuildContext context, {Bail? bail, DateTime? mois}) =>
    afficherFeuille<int>(context, builder: (_) => _CreationLoyers(bail: bail, mois: mois));

class _CreationLoyers extends ConsumerStatefulWidget {
  final Bail? bail;
  final DateTime? mois;

  const _CreationLoyers({this.bail, this.mois});

  @override
  ConsumerState<_CreationLoyers> createState() => _CreationLoyersState();
}

class _CreationLoyersState extends ConsumerState<_CreationLoyers> {
  late DateTime _mois = widget.mois ?? DateTime(DateTime.now().year, DateTime.now().month + 1);
  late bool _tous = widget.bail == null;
  late Bail? _bail = widget.bail;
  bool _envoi = false;

  Future<void> _choisirMois() async {
    final choisi = await showDialog<DateTime>(
      context: context,
      builder: (_) => MonthPickerDialog(initialYear: _mois.year, initialMonth: _mois.month),
    );
    if (choisi != null && mounted) setState(() => _mois = DateTime(choisi.year, choisi.month));
  }

  Future<void> _choisirBail() async {
    final repo = ref.read(bailRepositoryProvider);
    final b = await Navigator.push<Bail>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionPage<Bail>(
          titre: 'Bail',
          hintRecherche: 'Locataire, logement, référence…',
          emptyMessage: 'Aucun bail actif.',
          fetcherPour: (r) => (page, size) =>
              repo.getPage(page: page, size: size, statut: StatutBail.actif, recherche: r),
          titreItem: (b) => b.locataireNom ?? b.reference ?? '',
          sousTitreItem: (b) => '${b.logement} · ${formatMontant(b.montantMensuel)}/mois',
        ),
      ),
    );
    if (b != null) setState(() => _bail = b);
  }

  Future<void> _creer() async {
    if (!_tous && _bail == null) {
      showError(context, 'Choisissez le bail concerné.');
      return;
    }
    setState(() => _envoi = true);
    final result = await ref
        .read(loyerRepositoryProvider)
        .genererEcheances(jusquA: _mois, bailId: _tous ? null : _bail!.id);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (n) {
      showSuccess(
          context,
          n == 0
              ? 'Les loyers de ${formatMois(_mois).toLowerCase()} existaient déjà.'
              : '$n loyer(s) créé(s) jusqu\'à ${formatMois(_mois).toLowerCase()}.');
      Navigator.pop(context, n);
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
            const EnteteFeuille(
              icone: Icons.playlist_add_rounded,
              titre: 'Créer des loyers',
              sousTitre: 'Pour les mois pas encore émis',
            ),
            const SizedBox(height: 18),
            ChampEtiquete(
              label: 'Jusqu\'au mois',
              obligatoire: true,
              child: PiluleCliquable(
                valeur: formatMois(_mois),
                hint: 'Choisir un mois',
                onTap: _choisirMois,
                suffixe: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.hint),
                ),
              ),
            ),
            kGapChamps,
            if (widget.bail == null) ...[
              const EtiquetteChamp('Pour'),
              const SizedBox(height: 6),
              _Portee(tous: _tous, onChanged: (t) => setState(() => _tous = t)),
              kGapChamps,
            ],
            if (!_tous)
              ChampEtiquete(
                label: 'Bail',
                obligatoire: true,
                child: PiluleCliquable(
                  valeur: _bail == null ? null : '${_bail!.locataireNom ?? ''} · ${_bail!.logement}',
                  hint: 'Choisir un bail actif',
                  actif: widget.bail == null,
                  onTap: _choisirBail,
                  suffixe: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.hint),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les loyers manquants jusqu\'à ${formatMois(_mois).toLowerCase()} inclus sont créés ; '
                    'un loyer déjà émis n\'est jamais recréé. Au plus 12 mois à l\'avance.',
                    style: TextStyle(fontSize: 12, color: AppColors.dark, height: 1.35),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            BoutonPrincipal(
              label: 'Créer les loyers',
              icon: Icons.check_rounded,
              loading: _envoi,
              onPressed: _creer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bascule « Tous les baux actifs / Un bail ».
class _Portee extends StatelessWidget {
  final bool tous;
  final ValueChanged<bool> onChanged;

  const _Portee({required this.tous, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget segment(bool valeur, String libelle, IconData icone) {
      final actif = tous == valeur;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(valeur),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: actif ? AppColors.blanc : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: actif
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                  : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icone, size: 16, color: actif ? AppColors.primaryDark : AppColors.hint),
              const SizedBox(width: 6),
              Text(libelle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                      color: actif ? AppColors.dark : AppColors.label)),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        segment(true, 'Tous les baux', Icons.select_all_rounded),
        const SizedBox(width: 4),
        segment(false, 'Un bail', Icons.description_outlined),
      ]),
    );
  }
}
