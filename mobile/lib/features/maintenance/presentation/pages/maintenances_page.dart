import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/debounce.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/statut_filtre_chip.dart';
import '../../../immeuble/domain/entities/immeuble.dart';
import '../../../immeuble/presentation/widgets/pastille_filtre_bien.dart';
import '../../domain/entities/maintenance.dart';
import '../providers/maintenance_providers.dart';
import '../widgets/maintenance_tile.dart';
import 'maintenance_detail_page.dart';
import 'maintenance_form_page.dart';

class MaintenancesPage extends ConsumerStatefulWidget {
  const MaintenancesPage({super.key});

  @override
  ConsumerState<MaintenancesPage> createState() => _MaintenancesPageState();
}

class _MaintenancesPageState extends ConsumerState<MaintenancesPage> {
  final _listKey = GlobalKey<PagedListViewState<Maintenance>>();
  final _debounce = Debouncer();
  String _recherche = '';
  StatutMaintenance? _statut;

  /// Bien filtré : seules ses interventions (parties communes et logements).
  Immeuble? _bien;

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _listKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(maintenanceRepositoryProvider);
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: ChampRecherche(
              hint: 'Titre, prestataire, logement…',
              onChanged: (v) => _debounce.run(() => setState(() => _recherche = v.trim())),
              onAjouter: () => _ouvrir(const MaintenanceFormPage()),
              ajouterTooltip: 'Signaler une intervention',
            ),
          ),
          FiltresStatut<StatutMaintenance?>(
            options: [null, ...StatutMaintenance.values],
            selection: _statut,
            libelle: (s) => s?.libelle ?? 'Toutes',
            onSelected: (s) => setState(() => _statut = s),
            debut: PastilleFiltreBien(
              bien: _bien,
              sousTitre: 'Interventions sur ce bien et ses logements',
              onChanged: (b) => setState(() => _bien = b),
            ),
          ),
          Expanded(
            child: PagedListView<Maintenance>(
              key: _listKey,
              filtresKey: (_recherche, _statut, _bien?.id),
              fetcher: (page, size) => repo.getPage(
                  page: page, size: size, immeubleId: _bien?.id, statut: _statut, recherche: _recherche),
              emptyIcon: Icons.build_outlined,
              emptyMessage: _bien == null ? 'Aucune intervention.' : 'Aucune intervention pour ${_bien!.nom}.',
              emptyActionLabel: _bien == null ? null : 'Voir tous les biens',
              onEmptyAction: _bien == null ? null : () => setState(() => _bien = null),
              emptyActionIcon: Icons.filter_alt_off_outlined,
              itemBuilder: (context, m) => MaintenanceTile(
                maintenance: m,
                onTap: () => _ouvrir(MaintenanceDetailPage(maintenanceId: m.id!)),
              ),
            ),
          ),
        ],
    );
  }
}
