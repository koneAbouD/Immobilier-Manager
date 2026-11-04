import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/debounce.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/statut_filtre_chip.dart';
import '../../domain/entities/bail.dart';
import '../providers/bail_providers.dart';
import '../widgets/baux_liste.dart';
import 'bail_detail_page.dart';
import 'bail_form_page.dart';

class BauxPage extends ConsumerStatefulWidget {
  const BauxPage({super.key});

  @override
  ConsumerState<BauxPage> createState() => _BauxPageState();
}

class _BauxPageState extends ConsumerState<BauxPage> {
  final _listKey = GlobalKey<PagedListViewState<Bail>>();
  final _debounce = Debouncer();
  String _recherche = '';
  StatutBail? _statut = StatutBail.actif;

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
    final repo = ref.watch(bailRepositoryProvider);
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: ChampRecherche(
              hint: 'Locataire, logement, référence…',
              onChanged: (v) => _debounce.run(() => setState(() => _recherche = v.trim())),
              onAjouter: () => _ouvrir(const BailFormPage()),
              ajouterTooltip: 'Signer un bail',
            ),
          ),
          FiltresStatut<StatutBail?>(
            options: [null, ...StatutBail.values],
            selection: _statut,
            libelle: (s) => s?.libelle ?? 'Tous',
            onSelected: (s) => setState(() => _statut = s),
          ),
          Expanded(
            child: PagedListView<Bail>(
              key: _listKey,
              filtresKey: (_recherche, _statut),
              fetcher: (page, size) =>
                  repo.getPage(page: page, size: size, statut: _statut, recherche: _recherche),
              emptyIcon: Icons.description_outlined,
              emptyMessage: 'Aucun bail.',
              itemBuilder: (context, b) =>
                  BailTile(bail: b, onTap: () => _ouvrir(BailDetailPage(bailId: b.id!))),
            ),
          ),
        ],
    );
  }
}
