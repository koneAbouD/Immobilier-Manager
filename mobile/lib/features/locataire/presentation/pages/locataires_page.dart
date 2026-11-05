import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/debounce.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/statut_filtre_chip.dart';
import '../../domain/entities/locataire_resume.dart';
import '../providers/locataire_providers.dart';
import 'locataire_detail_page.dart';
import 'locataire_form_page.dart';

/// Onglet « Locataires » : chaque locataire avec son logement et l'état de ses
/// loyers, les retards en tête. Les filtres affichent combien de locataires
/// tombent dans chaque situation.
class LocatairesPage extends ConsumerStatefulWidget {
  const LocatairesPage({super.key});

  @override
  ConsumerState<LocatairesPage> createState() => _LocatairesPageState();
}

class _LocatairesPageState extends ConsumerState<LocatairesPage> {
  final _listKey = GlobalKey<PagedListViewState<LocataireResume>>();
  final _debounce = Debouncer();
  String _recherche = '';
  SituationLocataire? _situation;

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  void _rafraichir() {
    _listKey.currentState?.refresh();
    ref.invalidate(comptesSituationsProvider(_recherche));
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(locataireRepositoryProvider);
    final comptes = ref.watch(comptesSituationsProvider(_recherche)).valueOrNull;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: ChampRecherche(
            hint: 'Nom, téléphone, logement…',
            onChanged: (v) => _debounce.run(() => setState(() => _recherche = v.trim())),
            onAjouter: () => _ouvrir(const LocataireFormPage()),
            ajouterTooltip: 'Ajouter un locataire',
          ),
        ),
        FiltresStatut<SituationLocataire?>(
          options: const [null, ...SituationLocataire.values],
          selection: _situation,
          libelle: (s) {
            final libelle = s?.libelle ?? 'Tous';
            return comptes == null ? libelle : '$libelle  ${comptes.pour(s)}';
          },
          onSelected: (s) => setState(() => _situation = s),
        ),
        Expanded(
          child: PagedListView<LocataireResume>(
            key: _listKey,
            filtresKey: (_recherche, _situation),
            fetcher: (page, size) => repo.getResumes(
                page: page, size: size, recherche: _recherche, situation: _situation),
            emptyIcon: Icons.people_outline,
            emptyMessage: _situation == null ? 'Aucun locataire.' : 'Aucun locataire dans cette situation.',
            emptyActionLabel: _situation == null ? 'Ajouter un locataire' : null,
            onEmptyAction: _situation == null ? () => _ouvrir(const LocataireFormPage()) : null,
            itemBuilder: (context, l) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: CarteLocataire(
                locataire: l,
                onTap: () => _ouvrir(LocataireDetailPage(locataireId: l.id)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Carte d'un locataire dans la liste : initiales teintées de sa situation,
/// logement en cours, et à droite ce qui demande une action (montant en
/// retard, contrat à faire signer) ou la mention « À jour ».
class CarteLocataire extends StatelessWidget {
  final LocataireResume locataire;
  final VoidCallback onTap;

  const CarteLocataire({super.key, required this.locataire, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = locataire;
    final enRetard = l.situation == SituationLocataire.enRetard;
    final couleur = l.situation.couleur;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: enRetard ? AppColors.error.withValues(alpha: 0.3) : Colors.transparent),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(l.initiales,
                      style: TextStyle(color: couleur, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.nomComplet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                      const SizedBox(height: 3),
                      Row(children: [
                        if (l.typeLogement != null) ...[
                          Icon(l.typeLogement!.icone, size: 13, color: AppColors.grey500),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(l.logement,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Etat(locataire: l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Etat extends StatelessWidget {
  final LocataireResume locataire;

  const _Etat({required this.locataire});

  @override
  Widget build(BuildContext context) {
    final l = locataire;
    if (l.situation == SituationLocataire.enRetard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatMontant(l.montantEnRetard),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.error)),
          const SizedBox(height: 3),
          PastilleStatut(
              l.joursRetard > 0 ? '${l.joursRetard} j de retard' : 'En retard', AppColors.error),
        ],
      );
    }
    if (l.contratsASigner > 0) return PastilleStatut('Contrat à signer', AppColors.warning);
    return PastilleStatut(l.situation.libelle, l.situation.couleur);
  }
}
