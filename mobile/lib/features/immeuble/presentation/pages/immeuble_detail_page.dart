import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../appartement/domain/entities/appartement.dart';
import '../../../appartement/presentation/pages/appartement_detail_page.dart';
import '../../../appartement/presentation/pages/appartement_form_page.dart';
import '../../../appartement/presentation/providers/appartement_providers.dart';
import '../../domain/entities/immeuble.dart';
import '../providers/immeuble_providers.dart';
import 'immeuble_form_page.dart';

class ImmeubleDetailPage extends ConsumerStatefulWidget {
  final int immeubleId;

  const ImmeubleDetailPage({super.key, required this.immeubleId});

  @override
  ConsumerState<ImmeubleDetailPage> createState() => _ImmeubleDetailPageState();
}

class _ImmeubleDetailPageState extends ConsumerState<ImmeubleDetailPage> {
  final _listKey = GlobalKey<PagedListViewState<Appartement>>();

  void _rafraichir() {
    ref.invalidate(immeubleDetailProvider(widget.immeubleId));
    _listKey.currentState?.refresh();
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _rafraichir();
  }

  Future<void> _supprimer(Immeuble immeuble) async {
    final ok = await confirmer(context,
        titre: 'Supprimer l\'immeuble ?',
        message: '« ${immeuble.nom} » sera définitivement supprimé.',
        action: 'Supprimer',
        destructive: true);
    if (!ok || !mounted) return;
    final result = await ref.read(immeubleRepositoryProvider).delete(immeuble.id!);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      ref.invalidate(immeublesListeProvider);
      showSuccess(context, 'Immeuble supprimé.');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(immeubleDetailProvider(widget.immeubleId));
    final repoAppartements = ref.watch(appartementRepositoryProvider);

    return async.when(
      loading: () => const Scaffold(
          appBar: AppHeader(title: ''),
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: const AppHeader(title: ''),
        body: ErrorView(message: '$e', onRetry: _rafraichir),
      ),
      data: (immeuble) => Scaffold(
        appBar: AppHeader(
          title: 'Immeuble',
          action: ActionsDetail(
            onModifier: () => _ouvrir(ImmeubleFormPage(immeuble: immeuble)),
            onSupprimer: () => _supprimer(immeuble),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                children: [
                  DetailHeroCard(
                    icon: Icons.apartment_rounded,
                    titre: immeuble.nom,
                    sousTitre: immeuble.localisation,
                    statutLabel: '${immeuble.tauxOccupation} % occupé',
                    statutColor: AppColors.primaryDark,
                  ),
                  DetailInfoCard(children: [
                    DetailInfoRow(Icons.place_outlined, 'Adresse', immeuble.adresse),
                    DetailInfoRow(Icons.map_outlined, 'Localisation', immeuble.localisation),
                    DetailInfoRow(Icons.layers_outlined, 'Étages', immeuble.nombreEtages?.toString()),
                    DetailInfoRow(Icons.door_front_door_outlined, 'Logements',
                        '${immeuble.nombreOccupes}/${immeuble.nombreAppartements} occupés · ${immeuble.nombreLibres} libre(s)'),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionTitre(
                'Logements',
                action: BoutonTexte(
                  label: 'Ajouter',
                  icon: Icons.add_rounded,
                  onTap: () => _ouvrir(AppartementFormPage(immeubleId: immeuble.id!)),
                ),
              ),
            ),
            Expanded(
              child: PagedListView<Appartement>(
                key: _listKey,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                fetcher: (page, size) => repoAppartements.getPage(
                    page: page, size: size, immeubleId: widget.immeubleId),
                emptyIcon: Icons.door_front_door_outlined,
                emptyMessage: 'Aucun logement dans cet immeuble.',
                emptyActionLabel: 'Ajouter un logement',
                onEmptyAction: () => _ouvrir(AppartementFormPage(immeubleId: immeuble.id!)),
                itemBuilder: (context, a) => AppartementTile(
                  appartement: a,
                  onTap: () => _ouvrir(AppartementDetailPage(appartementId: a.id!)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de logement réutilisée dans les listes.
class AppartementTile extends StatelessWidget {
  final Appartement appartement;
  final VoidCallback onTap;

  const AppartementTile({super.key, required this.appartement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = appartement;
    return ListeCarte(
      icon: a.type.icone,
      couleur: a.statut.couleur,
      titre: '${a.reference} · ${a.type.libelle}',
      valeur: formatMontant(a.montantMensuel),
      sousTitre: a.libelleEtage,
      detail: 'par mois, charges comprises',
      badge: PastilleStatut(a.statut.libelle, a.statut.couleur),
      onTap: onTap,
    );
  }
}
