import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../domain/entities/bail.dart';
import '../pages/bail_detail_page.dart';
import '../providers/bail_providers.dart';

/// Baux d'un logement ou d'un locataire, intégrés dans un écran de détail
/// (liste non défilante : l'historique d'un logement reste court).
class BauxListe extends ConsumerStatefulWidget {
  final int? appartementId;
  final int? locataireId;
  final VoidCallback? onChange;

  const BauxListe({super.key, this.appartementId, this.locataireId, this.onChange});

  @override
  ConsumerState<BauxListe> createState() => _BauxListeState();
}

class _BauxListeState extends ConsumerState<BauxListe> {
  late final Future<Either<Failure, PageResult<Bail>>> _future = ref
      .read(bailRepositoryProvider)
      .getPage(size: 50, appartementId: widget.appartementId, locataireId: widget.locataireId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, PageResult<Bail>>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.data!.fold(
          (f) => Text(f.message, style: TextStyle(color: AppColors.error)),
          (page) => page.content.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun bail.', style: TextStyle(color: AppColors.grey500)),
                )
              : Column(
                  children: page.content
                      .map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: BailTile(
                            bail: b,
                            afficherLocataire: widget.locataireId == null,
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => BailDetailPage(bailId: b.id!)));
                              widget.onChange?.call();
                            },
                          )))
                      .toList(),
                ),
        );
      },
    );
  }
}

class BailTile extends StatelessWidget {
  final Bail bail;
  final bool afficherLocataire;
  final VoidCallback onTap;

  const BailTile({super.key, required this.bail, required this.onTap, this.afficherLocataire = true});

  @override
  Widget build(BuildContext context) {
    final b = bail;
    final periode = b.estActif
        ? 'Depuis le ${formatDate(b.dateDebut)}'
        : '${formatDate(b.dateDebut)} → ${formatDate(b.dateResiliation)}';
    return ListeCarte(
      icon: Icons.description_outlined,
      couleur: b.statut.couleur,
      titre: afficherLocataire ? (b.locataireNom ?? '') : b.logement,
      valeur: formatMontant(b.montantMensuel),
      sousTitre: afficherLocataire ? b.logement : null,
      detail: b.estActif ? '$periode · ${b.statutContrat.libelle}' : periode,
      badge: PastilleStatut(b.statut.libelle, b.statut.couleur),
      onTap: onTap,
    );
  }
}
