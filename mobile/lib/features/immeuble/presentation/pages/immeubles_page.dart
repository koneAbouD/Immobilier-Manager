import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/debounce.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../domain/entities/immeuble.dart';
import '../providers/immeuble_providers.dart';
import 'immeuble_detail_page.dart';
import 'immeuble_form_page.dart';

/// Section « Biens » : la liste des biens (immeubles, cours basses, terrains),
/// porte d'entrée vers les logements.
class ImmeublesPage extends ConsumerStatefulWidget {
  const ImmeublesPage({super.key});

  @override
  ConsumerState<ImmeublesPage> createState() => _ImmeublesPageState();
}

class _ImmeublesPageState extends ConsumerState<ImmeublesPage> {
  final _listKey = GlobalKey<PagedListViewState<Immeuble>>();
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
    final repo = ref.watch(immeubleRepositoryProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ChampRecherche(
            hint: 'Nom, commune, ville…',
            onChanged: (v) => _debounce.run(() => setState(() => _recherche = v.trim())),
            onAjouter: () => _ouvrir(const ImmeubleFormPage()),
            ajouterTooltip: 'Ajouter un bien',
          ),
        ),
        Expanded(
          child: PagedListView<Immeuble>(
            key: _listKey,
            filtresKey: _recherche,
            fetcher: (page, size) => repo.getPage(page: page, size: size, recherche: _recherche),
            emptyIcon: Icons.apartment,
            emptyMessage: 'Aucun bien.\nAjoutez votre premier bien.',
            emptyActionLabel: 'Ajouter un bien',
            onEmptyAction: () => _ouvrir(const ImmeubleFormPage()),
            itemBuilder: (context, i) => _ImmeubleCard(
              immeuble: i,
              onTap: () => _ouvrir(ImmeubleDetailPage(immeubleId: i.id!)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImmeubleCard extends StatelessWidget {
  final Immeuble immeuble;
  final VoidCallback onTap;

  const _ImmeubleCard({required this.immeuble, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final i = immeuble;
    return Material(
      color: AppColors.blanc,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(immeuble.type.icone, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            i.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: AppColors.dark,
                            ),
                          ),
                        ),
                        Text(
                          i.type == TypeBien.terrain
                              ? (i.nombreOccupes > 0 ? 'Loué' : 'Libre')
                              : '${i.tauxOccupation} %',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    if (i.localisation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        i.localisation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.grey500),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: i.nombreAppartements == 0 ? 0 : i.tauxOccupation / 100,
                        minHeight: 5,
                        color: AppColors.primary,
                        backgroundColor: AppColors.grey200,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i.type == TypeBien.terrain
                          ? 'Terrain loué nu'
                          : '${i.nombreOccupes}/${i.nombreAppartements} occupés · ${i.nombreLibres} libre(s)',
                      style: TextStyle(fontSize: 11.5, color: AppColors.label),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: AppColors.hint),
            ],
          ),
        ),
      ),
    );
  }
}
