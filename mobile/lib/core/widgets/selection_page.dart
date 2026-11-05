import 'package:flutter/material.dart';

import '../pagination/paged_list_notifier.dart';
import '../theme/app_colors.dart';
import 'app_header.dart';
import 'debounce.dart';
import 'form_fields.dart';
import 'liste_carte.dart';
import 'paged_list_view.dart';

/// Écran de sélection d'un élément dans une liste paginée avec recherche
/// (logement libre, locataire…). Renvoie l'élément choisi via Navigator.pop.
class SelectionPage<T> extends StatefulWidget {
  final String titre;
  final String hintRecherche;
  final PageFetcher<T> Function(String recherche) fetcherPour;
  final String Function(T) titreItem;
  final String? Function(T)? sousTitreItem;
  final IconData icone;
  final String emptyMessage;

  const SelectionPage({
    super.key,
    required this.titre,
    required this.fetcherPour,
    required this.titreItem,
    this.sousTitreItem,
    this.hintRecherche = 'Rechercher…',
    this.icone = Icons.radio_button_unchecked_rounded,
    this.emptyMessage = 'Aucun résultat.',
  });

  @override
  State<SelectionPage<T>> createState() => _SelectionPageState<T>();
}

class _SelectionPageState<T> extends State<SelectionPage<T>> {
  final _debounce = Debouncer();
  String _recherche = '';

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: widget.titre),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ChampRecherche(
              hint: widget.hintRecherche,
              onChanged: (v) => _debounce.run(() => setState(() => _recherche = v.trim())),
            ),
          ),
          Expanded(
            child: PagedListView<T>(
              filtresKey: _recherche,
              fetcher: widget.fetcherPour(_recherche),
              emptyMessage: widget.emptyMessage,
              itemBuilder: (context, item) {
                final sousTitre = widget.sousTitreItem?.call(item);
                return ListeCarte(
                  icon: widget.icone,
                  titre: widget.titreItem(item),
                  sousTitre: sousTitre,
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ de formulaire qui ouvre une [SelectionPage] au tap.
class ChampSelection<T> extends StatelessWidget {
  final String label;
  final String? valeurAffichee;
  final Future<T?> Function() ouvrir;
  final ValueChanged<T> onSelected;
  final bool obligatoire;
  final bool actif;

  const ChampSelection({
    super.key,
    required this.label,
    required this.valeurAffichee,
    required this.ouvrir,
    required this.onSelected,
    this.obligatoire = false,
    this.actif = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: valeurAffichee,
      validator: (_) =>
          obligatoire && valeurAffichee == null ? 'Champ obligatoire.' : null,
      builder: (state) => ChampEtiquete(
        label: label,
        obligatoire: obligatoire,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PiluleCliquable(
            valeur: valeurAffichee,
            hint: 'Choisir…',
            actif: actif,
            erreur: state.hasError,
            onTap: () async {
              final choix = await ouvrir();
              if (choix != null) {
                onSelected(choix);
                state.didChange('ok');
              }
            },
            suffixe: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.hint),
            ),
          ),
          ErreurChamp(state.errorText),
        ]),
      ),
    );
  }
}
