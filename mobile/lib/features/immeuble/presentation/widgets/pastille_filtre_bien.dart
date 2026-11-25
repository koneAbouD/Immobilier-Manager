import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../domain/entities/immeuble.dart';
import '../providers/immeuble_providers.dart';

/// Pastille « Bien » en tête des filtres d'une liste (locataires, loyers,
/// travaux) : vide, elle propose de choisir un bien ; remplie, elle affiche
/// son nom et une croix pour revenir à tous. [sousTitre] explique, dans la
/// feuille de choix, ce que le filtre retient.
///
/// La pastille écoute la liste des biens : elle est chargée dès l'affichage de
/// la page, et la feuille s'ouvre déjà remplie, à sa hauteur finale, au lieu
/// de monter vide puis de sauter quand les biens arrivent.
class PastilleFiltreBien extends ConsumerWidget {
  final Immeuble? bien;
  final ValueChanged<Immeuble?> onChanged;
  final String sousTitre;

  const PastilleFiltreBien({
    super.key,
    required this.bien,
    required this.onChanged,
    this.sousTitre = 'Seuls les éléments de ce bien sont affichés',
  });

  Future<void> _choisir(BuildContext context) async {
    final choix = await afficherFeuille<_Choix>(
      context,
      animation: kAnimationFeuilleDouce,
      builder: (_) => _FeuilleBiens(selection: bien, sousTitre: sousTitre),
    );
    if (choix != null) onChanged(choix.bien);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Préchargement : garde la liste vivante tant que la page est affichée.
    ref.watch(immeublesListeProvider);
    final actif = bien != null;
    final accent = AppColors.primary;
    return Semantics(
      button: true,
      selected: actif,
      label: actif ? 'Bien : ${bien!.nom}' : 'Filtrer par bien',
      child: GestureDetector(
        onTap: () => _choisir(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 8),
          padding: EdgeInsets.only(left: 10, right: actif ? 4 : 8),
          constraints: const BoxConstraints(maxWidth: 190),
          decoration: BoxDecoration(
            color: actif ? accent : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: actif ? accent : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(actif ? bien!.type.icone : Icons.apartment_rounded,
                  size: 15, color: actif ? Colors.white : AppColors.label),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  actif ? bien!.nom : 'Tous les biens',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                    color: actif ? Colors.white : AppColors.label,
                  ),
                ),
              ),
              if (actif)
                // Zone de toucher plus large que l'icône : retire le filtre sans rouvrir la feuille.
                InkResponse(
                  onTap: () => onChanged(null),
                  radius: 16,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 15, color: Colors.white),
                  ),
                )
              else ...[
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: AppColors.label),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Résultat de la feuille : distingue « Tous les biens » (bien nul) d'une
/// feuille refermée sans choix (résultat nul).
class _Choix {
  final Immeuble? bien;
  const _Choix(this.bien);
}

/// Feuille de choix d'un bien : « Tous les biens » puis chaque bien, avec son
/// occupation ; une recherche apparaît dès que la liste s'allonge.
class _FeuilleBiens extends ConsumerStatefulWidget {
  final Immeuble? selection;
  final String sousTitre;

  const _FeuilleBiens({required this.selection, required this.sousTitre});

  @override
  ConsumerState<_FeuilleBiens> createState() => _FeuilleBiensState();
}

class _FeuilleBiensState extends ConsumerState<_FeuilleBiens> {
  static const _seuilRecherche = 6;
  String _recherche = '';

  static String _normaliser(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  void _retenir(_Choix choix) {
    HapticFeedback.selectionClick();
    Navigator.pop(context, choix);
  }

  @override
  Widget build(BuildContext context) {
    final biens = ref.watch(immeublesListeProvider);
    // Hauteur bornée : au-delà, la liste défile dans la feuille, qui laisse
    // voir la page derrière elle.
    final hauteurMax = MediaQuery.sizeOf(context).height * 0.72;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: hauteurMax),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnteteFeuille(
            icone: Icons.apartment_rounded,
            titre: 'Filtrer par bien',
            sousTitre: widget.sousTitre,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: biens.when(
              // Lignes fantômes à la hauteur des vraies : la feuille ne saute pas.
              loading: () => const _LignesFantomes(),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(messageErreur(e), textAlign: TextAlign.center, style: TextStyle(color: AppColors.label)),
              ),
              data: (tous) {
                final motif = _normaliser(_recherche.trim());
                final liste = motif.isEmpty
                    ? tous
                    : tous.where((b) => _normaliser('${b.nom} ${b.localisation}').contains(motif)).toList();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (tous.length > _seuilRecherche) ...[
                      TextField(
                        autofocus: false,
                        onChanged: (v) => setState(() => _recherche = v),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un bien…',
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.hint),
                          filled: true,
                          fillColor: AppColors.fieldFill,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (motif.isEmpty)
                            _LigneBien(
                              icone: Icons.select_all_rounded,
                              titre: 'Tous les biens',
                              detail: '${tous.length} bien${tous.length > 1 ? 's' : ''}',
                              choisi: widget.selection == null,
                              onTap: () => _retenir(const _Choix(null)),
                            ),
                          for (final b in liste)
                            _LigneBien(
                              icone: b.type.icone,
                              titre: b.nom,
                              detail: [
                                if (b.localisation.isNotEmpty) b.localisation,
                                '${b.nombreOccupes}/${b.nombreAppartements} occupé${b.nombreOccupes > 1 ? 's' : ''}',
                              ].join(' · '),
                              choisi: widget.selection?.id == b.id,
                              onTap: () => _retenir(_Choix(b)),
                            ),
                          if (liste.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                tous.isEmpty ? 'Aucun bien enregistré.' : 'Aucun bien ne correspond.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.label),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Trois lignes grisées à la taille d'une ligne de bien, pendant le chargement.
class _LignesFantomes extends StatelessWidget {
  const _LignesFantomes();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(color: AppColors.cardTint, borderRadius: BorderRadius.circular(14)),
          ),
      ],
    );
  }
}

class _LigneBien extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String detail;
  final bool choisi;
  final VoidCallback onTap;

  const _LigneBien({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.choisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: choisi ? AppColors.primaryTint : AppColors.cardTint,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: choisi ? AppColors.primary : Colors.transparent, width: 1.4),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icone, size: 20, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.label),
                      ),
                    ],
                  ),
                ),
                if (choisi) Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
