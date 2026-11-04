import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/debounce.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../domain/entities/locataire.dart';
import '../providers/locataire_providers.dart';
import 'locataire_detail_page.dart';
import 'locataire_form_page.dart';

class LocatairesPage extends ConsumerStatefulWidget {
  const LocatairesPage({super.key});

  @override
  ConsumerState<LocatairesPage> createState() => _LocatairesPageState();
}

class _LocatairesPageState extends ConsumerState<LocatairesPage> {
  final _listKey = GlobalKey<PagedListViewState<Locataire>>();
  final _debounce = Debouncer();
  String _recherche = '';

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
    final repo = ref.watch(locataireRepositoryProvider);
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ChampRecherche(
              hint: 'Nom, prénom, téléphone…',
              onChanged: (v) => _debounce.run(() => setState(() => _recherche = v.trim())),
              onAjouter: () => _ouvrir(const LocataireFormPage()),
              ajouterTooltip: 'Ajouter un locataire',
            ),
          ),
          Expanded(
            child: PagedListView<Locataire>(
              key: _listKey,
              filtresKey: _recherche,
              fetcher: (page, size) => repo.getPage(page: page, size: size, recherche: _recherche),
              emptyIcon: Icons.people_outline,
              emptyMessage: 'Aucun locataire.',
              emptyActionLabel: 'Ajouter un locataire',
              onEmptyAction: () => _ouvrir(const LocataireFormPage()),
              itemBuilder: (context, l) => ListeCarte(
                initiales: l.initiales,
                couleur: AppColors.primaryDark,
                titre: l.nomComplet,
                sousTitre: [l.telephone, l.profession].whereType<String>().join(' · '),
                onTap: () => _ouvrir(LocataireDetailPage(locataireId: l.id!)),
              ),
            ),
          ),
        ],
    );
  }
}
