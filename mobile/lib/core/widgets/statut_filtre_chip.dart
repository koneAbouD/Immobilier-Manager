import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pastille de filtre par statut des listes (baux, échéances, interventions).
///
/// Sélectionnée, elle se **teinte** de la couleur d'accent — fond clair,
/// bordure et texte à l'accent — plutôt que de s'en remplir : c'est un contrôle
/// de l'interface, pas un statut, il suit donc le thème.
class StatutFiltreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const StatutFiltreChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 8),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.5) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? accent : AppColors.label,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rangée défilante de [StatutFiltreChip], de hauteur fixe.
class FiltresStatut<T> extends StatelessWidget {
  final List<T> options;
  final T selection;
  final String Function(T) libelle;
  final ValueChanged<T> onSelected;

  const FiltresStatut({
    super.key,
    required this.options,
    required this.selection,
    required this.libelle,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        children: [
          for (final o in options)
            StatutFiltreChip(
              label: libelle(o),
              selected: o == selection,
              onTap: () => onSelected(o),
            ),
        ],
      ),
    );
  }
}
