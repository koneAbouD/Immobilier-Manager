import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../bail/presentation/pages/bail_form_page.dart';
import '../../../immeuble/presentation/pages/immeuble_form_page.dart';
import '../../../locataire/presentation/pages/locataire_form_page.dart';
import '../../../maintenance/presentation/pages/maintenance_form_page.dart';
import '../../domain/entities/tableau_bord.dart';
import '../providers/tableau_bord_providers.dart';

/// Index des onglets de la barre de navigation (voir HomeScreen).
const _biens = 1;
const _locations = 2;
const _loyers = 3;
const _travaux = 4;

/// Accueil, au gabarit de celui de VTC Manager : carte en relief des loyers du
/// mois, grille d'accès rapides, puis les indicateurs du parc.
class TableauBordPage extends ConsumerWidget {
  /// Ouvre un autre onglet de l'accueil (index de la barre de navigation).
  final ValueChanged<int> onNaviguer;

  const TableauBordPage({super.key, required this.onNaviguer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tableauBordProvider);

    Future<void> ouvrir(Widget page) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      ref.invalidate(tableauBordProvider);
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
          message: '$e', onRetry: () => ref.invalidate(tableauBordProvider)),
      data: (t) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(tableauBordProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
          children: [
            _CarteLoyers(t: t, onEncaisser: () => onNaviguer(_loyers)),
            const SizedBox(height: 24),
            _AccesRapides(raccourcis: [
              (icon: Icons.apartment_outlined, label: 'Biens', onTap: () => onNaviguer(_biens)),
              (icon: Icons.people_outline, label: 'Locations', onTap: () => onNaviguer(_locations)),
              (icon: Icons.receipt_long_outlined, label: 'Loyers', onTap: () => onNaviguer(_loyers)),
              (icon: Icons.build_circle_outlined, label: 'Travaux', onTap: () => onNaviguer(_travaux)),
              (icon: Icons.draw_outlined, label: 'Nouveau bail', onTap: () => ouvrir(const BailFormPage())),
              (icon: Icons.person_add_alt_outlined, label: 'Locataire', onTap: () => ouvrir(const LocataireFormPage())),
              (icon: Icons.add_home_outlined, label: 'Immeuble', onTap: () => ouvrir(const ImmeubleFormPage())),
              (icon: Icons.report_problem_outlined, label: 'Signaler', onTap: () => ouvrir(const MaintenanceFormPage())),
            ]),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text('Vue d\'ensemble',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark)),
            ),
            Row(children: [
              Expanded(
                child: _Indicateur(
                  icone: Icons.warning_amber_rounded,
                  couleur: AppColors.error,
                  valeur: formatMontant(t.impayes),
                  libelle: '${t.nombreEcheancesEnRetard} loyer(s) en retard',
                  onTap: () => onNaviguer(_loyers),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Indicateur(
                  icone: Icons.apartment_rounded,
                  couleur: AppColors.primaryDark,
                  valeur: '${t.tauxOccupation} %',
                  libelle:
                      '${t.nombreAppartementsOccupes}/${t.nombreAppartements} logements occupés',
                  onTap: () => onNaviguer(_biens),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _Indicateur(
                  icone: Icons.people_outline,
                  couleur: AppColors.info,
                  valeur: '${t.nombreLocatairesActifs}',
                  libelle: 'locataire(s) actif(s)',
                  onTap: () => onNaviguer(_locations),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Indicateur(
                  icone: Icons.build_outlined,
                  couleur: AppColors.warning,
                  valeur: '${t.maintenancesOuvertes}',
                  libelle: t.maintenancesUrgentes > 0
                      ? 'intervention(s) ouverte(s) dont ${t.maintenancesUrgentes} urgente(s)'
                      : 'intervention(s) ouverte(s)',
                  onTap: () => onNaviguer(_travaux),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Carte en relief des loyers du mois : filet dégradé, fond teinté de l'accent,
/// montant encaissé en gros et bouton « Encaisser », comme la carte solde de
/// VTC Manager.
class _CarteLoyers extends StatelessWidget {
  final TableauBord t;
  final VoidCallback onEncaisser;

  const _CarteLoyers({required this.t, required this.onEncaisser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: AppColors.cardBorderGradient,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardTint,
          borderRadius: BorderRadius.circular(AppColors.cardInnerRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ligne 1 : pastille de période ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blanc,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.grey300),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_month_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 5),
                Text('Loyers de ${formatMois(t.periode)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 18),

            // ── Ligne 2 : montant encaissé | Encaisser ────────────────────
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMontant(t.loyersEncaisses),
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onEncaisser,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Encaisser'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('encaissés sur ${formatMontant(t.loyersAttendus)} attendus',
                style: TextStyle(fontSize: 12, color: AppColors.grey600)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: t.tauxRecouvrement / 100,
                minHeight: 6,
                color: AppColors.primary,
                backgroundColor: AppColors.grey200,
              ),
            ),

            // ── Ligne 3 : Recouvré | Reste à encaisser ────────────────────
            const SizedBox(height: 16),
            Divider(color: AppColors.grey200, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CardStat(
                    icon: Icons.pie_chart_outline_rounded,
                    label: 'Recouvré',
                    value: '${t.tauxRecouvrement} %',
                    color: AppColors.positive,
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.grey200),
                Expanded(
                  child: _CardStat(
                    icon: Icons.hourglass_bottom_rounded,
                    label: 'Reste à encaisser',
                    value: formatMontant(t.resteAEncaisser),
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CardStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.grey600, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

typedef _Raccourci = ({IconData icon, String label, VoidCallback onTap});

/// Grille des accès rapides : quatre colonnes sur téléphone, une seule rangée
/// sur tablette.
class _AccesRapides extends StatelessWidget {
  final List<_Raccourci> raccourcis;

  const _AccesRapides({required this.raccourcis});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tablette = constraints.maxWidth >= 600;
        final cercle = tablette ? 56.0 : 48.0;
        return GridView.builder(
          shrinkWrap: true,
          // Sans padding explicite, la grille reprendrait la marge basse de la
          // barre de navigation flottante (extendBody) et creuserait un vide.
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: raccourcis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: tablette ? raccourcis.length : 4,
            mainAxisExtent: cercle + 32,
            mainAxisSpacing: 14,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (_, i) {
            final r = raccourcis[i];
            return InkWell(
              onTap: r.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: cercle,
                    height: cercle,
                    decoration: BoxDecoration(
                      color: AppColors.fond(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(r.icon,
                        color: AppColors.primaryDark, size: tablette ? 28 : 24),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      r.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Indicateur extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String valeur;
  final String libelle;
  final VoidCallback onTap;

  const _Indicateur({
    required this.icone,
    required this.couleur,
    required this.valeur,
    required this.libelle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: couleur, size: 18),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valeur,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                        letterSpacing: -0.3)),
              ),
              const SizedBox(height: 2),
              Text(libelle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: AppColors.label)),
            ],
          ),
        ),
      ),
    );
  }
}
