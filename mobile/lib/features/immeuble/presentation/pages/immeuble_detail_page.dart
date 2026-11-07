import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/carte_position.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../appartement/domain/entities/appartement.dart';
import '../../../appartement/presentation/pages/appartement_detail_page.dart';
import '../../../appartement/presentation/pages/appartement_form_page.dart';
import '../../../appartement/presentation/providers/appartement_providers.dart';
import '../../../bail/presentation/pages/bail_form_page.dart';
import '../../../bail/presentation/widgets/baux_liste.dart';
import '../../domain/entities/immeuble.dart';
import '../providers/immeuble_providers.dart';
import '../widgets/galerie_photos_bien.dart';
import 'immeuble_form_page.dart';

/// Local unique d'un terrain : le terrain lui-même, créé avec le bien, sur
/// lequel se signent ses baux.
final _localTerrainProvider = FutureProvider.autoDispose.family<Appartement?, int>((ref, immeubleId) async {
  final result = await ref.watch(appartementRepositoryProvider).getPage(size: 1, immeubleId: immeubleId);
  return result.fold((f) => throw f.message, (p) => p.content.firstOrNull);
});

/// Locaux d'un immeuble ou d'une cour basse : peu nombreux, chargés d'un coup
/// pour tenir dans le défilement de la fiche.
final _locauxProvider = FutureProvider.autoDispose.family<List<Appartement>, int>((ref, immeubleId) async {
  final result = await ref.watch(appartementRepositoryProvider).getPage(size: 200, immeubleId: immeubleId);
  return result.fold((f) => throw f.message, (p) => p.content);
});

/// Fiche d'un bien : ses informations et sa position, puis ses locaux — ou,
/// pour un terrain, sa location (bail en cours et historique).
class ImmeubleDetailPage extends ConsumerStatefulWidget {
  final int immeubleId;

  const ImmeubleDetailPage({super.key, required this.immeubleId});

  @override
  ConsumerState<ImmeubleDetailPage> createState() => _ImmeubleDetailPageState();
}

class _ImmeubleDetailPageState extends ConsumerState<ImmeubleDetailPage> {

  int _version = 0;

  void _rafraichir() {
    ref.invalidate(immeubleDetailProvider(widget.immeubleId));
    ref.invalidate(_localTerrainProvider(widget.immeubleId));
    ref.invalidate(_locauxProvider(widget.immeubleId));
    ref.invalidate(photosBienProvider(widget.immeubleId));
    setState(() => _version++);
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _rafraichir();
  }

  Future<void> _supprimer(Immeuble immeuble) async {
    final ok = await confirmer(context,
        titre: 'Supprimer le bien ?',
        message: '« ${immeuble.nom} » sera définitivement supprimé.',
        action: 'Supprimer',
        destructive: true);
    if (!ok || !mounted) return;
    final result = await ref.read(immeubleRepositoryProvider).delete(immeuble.id!);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      ref.invalidate(immeublesListeProvider);
      showSuccess(context, 'Bien supprimé.');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(immeubleDetailProvider(widget.immeubleId));

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
          title: 'Bien',
          action: ActionsDetail(
            onModifier: () => _ouvrir(ImmeubleFormPage(immeuble: immeuble)),
            onSupprimer: () => _supprimer(immeuble),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _rafraichir(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              DetailHeroCard(
                icon: immeuble.type.icone,
                titre: immeuble.nom,
                sousTitre: immeuble.localisation,
                statutLabel: immeuble.type == TypeBien.terrain
                    ? (immeuble.nombreOccupes > 0 ? 'Loué' : 'Libre')
                    : '${immeuble.tauxOccupation} % occupé',
                statutColor: AppColors.primaryDark,
              ),
              DetailInfoCard(children: [
                DetailInfoRow(immeuble.type.icone, 'Type', immeuble.type.libelle),
                DetailInfoRow(Icons.place_outlined, 'Adresse', immeuble.adresse),
                DetailInfoRow(Icons.map_outlined, 'Localisation', immeuble.localisation),
                DetailInfoRow(Icons.layers_outlined, 'Étages', immeuble.nombreEtages?.toString()),
                DetailInfoRow(Icons.gps_fixed_rounded, 'Position',
                    immeuble.position == null ? null : formatPosition(immeuble.position!)),
                if (immeuble.type != TypeBien.terrain)
                  DetailInfoRow(Icons.door_front_door_outlined, 'Locaux',
                      '${immeuble.nombreOccupes}/${immeuble.nombreAppartements} occupés · ${immeuble.nombreLibres} libre(s)'),
              ]),
              if (immeuble.position != null) _CarteBien(position: immeuble.position!),
              const SizedBox(height: 4),
              GaleriePhotosBien(immeubleId: immeuble.id!),
              // Les locaux n'existent que pour un immeuble ou une cour basse ; un
              // terrain se loue tel quel.
              if (immeuble.type == TypeBien.terrain)
                _LocationTerrain(key: ValueKey(_version), immeubleId: immeuble.id!, onOuvrir: _ouvrir)
              else
                _Locaux(immeubleId: immeuble.id!, onOuvrir: _ouvrir),
            ],
          ),
        ),
      ),
    );
  }
}

/// Locaux d'un immeuble ou d'une cour basse, avec l'ajout d'un local.
class _Locaux extends ConsumerWidget {
  final int immeubleId;
  final Future<void> Function(Widget page) onOuvrir;

  const _Locaux({required this.immeubleId, required this.onOuvrir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void ajouter() => onOuvrir(AppartementFormPage(immeubleId: immeubleId));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitre(
        'Locaux',
        action: BoutonTexte(label: 'Ajouter', icon: Icons.add_rounded, onTap: ajouter),
      ),
      ref.watch(_locauxProvider(immeubleId)).when(
            loading: () => const Padding(
                padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => TextButton(
              onPressed: () => ref.invalidate(_locauxProvider(immeubleId)),
              child: Text('$e — Réessayer'),
            ),
            data: (locaux) => locaux.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(children: [
                      Text('Aucun local dans ce bien.', style: TextStyle(color: AppColors.grey500)),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: ajouter,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Ajouter un local'),
                      ),
                    ]),
                  )
                : Column(children: [
                    for (final a in locaux)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppartementTile(
                          appartement: a,
                          onTap: () => onOuvrir(AppartementDetailPage(appartementId: a.id!)),
                        ),
                      ),
                  ]),
          ),
    ]);
  }
}

/// Ligne d'un local réutilisée dans les listes.
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

/// Aperçu de la position du bien, avec l'itinéraire depuis ma position et la
/// copie des coordonnées (à coller dans Google Maps).
class _CarteBien extends StatefulWidget {
  final LatLng position;

  const _CarteBien({required this.position});

  @override
  State<_CarteBien> createState() => _CarteBienState();
}

class _CarteBienState extends State<_CarteBien> {
  bool _localisation = false;

  /// Relève ma position pour en faire le départ de l'itinéraire. Si elle est
  /// indisponible (GPS coupé, accès refusé), Google Maps partira de lui-même
  /// de la position du téléphone.
  Future<void> _itineraire() async {
    setState(() => _localisation = true);
    LatLng? origine;
    try {
      origine = await positionActuelle();
    } catch (_) {
      origine = null;
    }
    if (!mounted) return;
    setState(() => _localisation = false);
    if (!await ouvrirItineraire(widget.position, origine: origine) && mounted) {
      showError(context, 'Aucune application de cartes n\'est disponible.');
    }
  }

  Future<void> _copier() async {
    final texte = coordonneesGoogle(widget.position);
    try {
      // Certains navigateurs laissent la demande en suspens au lieu de la
      // refuser : passé ce délai, on bascule sur l'affichage de la position.
      await Clipboard.setData(ClipboardData(text: texte)).timeout(const Duration(seconds: 2));
      if (mounted) showSuccess(context, 'Position copiée : collez-la dans la recherche de Google Maps.');
    } catch (_) {
      // Presse-papiers refusé ou muet : on affiche la position pour qu'elle
      // se sélectionne à la main.
      if (!mounted) return;
      await informer(
        context,
        titre: 'Position du bien',
        icone: Icons.location_on_outlined,
        contenu: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sélectionnez-la, puis collez-la dans Google Maps :',
              style: TextStyle(fontSize: 13, color: AppColors.label)),
          const SizedBox(height: 10),
          SelectableText(texte,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
        ]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(children: [
        CartePosition(position: widget.position, hauteur: 150),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: BoutonPrincipal(
              label: 'Itinéraire',
              icon: Icons.directions_rounded,
              loading: _localisation,
              onPressed: _itineraire,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: BoutonSecondaire(
                label: 'Copier',
                icon: Icons.copy_rounded,
                onPressed: _copier,
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Location d'un terrain : son état, la signature d'un bail s'il est libre,
/// puis ses baux (en cours et passés).
class _LocationTerrain extends ConsumerWidget {
  final int immeubleId;
  final Future<void> Function(Widget page) onOuvrir;

  const _LocationTerrain({super.key, required this.immeubleId, required this.onOuvrir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_localTerrainProvider(immeubleId)).when(
          loading: () => const Padding(
              padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(_localTerrainProvider(immeubleId)),
              child: Text('$e — Réessayer'),
            ),
          ),
          data: (local) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitre('Location du terrain'),
              if (local == null)
                Text('Ce terrain n\'a pas de local de location.',
                    style: TextStyle(fontSize: 13, color: AppColors.label))
              else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blanc,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: local.statut.couleur.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(Icons.landscape_outlined, color: local.statut.couleur, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        local.statut == StatutAppartement.libre
                            ? 'Libre : le terrain peut être loué.'
                            : local.statut == StatutAppartement.occupe
                                ? 'Loué : un bail est en cours.'
                                : local.statut.libelle,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.dark),
                      ),
                    ),
                    PastilleStatut(local.statut.libelle, local.statut.couleur),
                  ]),
                ),
                if (local.statut == StatutAppartement.libre) ...[
                  const SizedBox(height: 12),
                  BoutonPrincipal(
                    label: 'Signer un bail',
                    icon: Icons.draw_outlined,
                    onPressed: () => onOuvrir(BailFormPage(appartementInitial: local)),
                  ),
                ],
                const SizedBox(height: 8),
                const SectionTitre('Baux'),
                BauxListe(appartementId: local.id),
              ],
            ],
          ),
        );
  }
}
