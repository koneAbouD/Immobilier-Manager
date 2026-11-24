import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

// Éléments communs à la signature et à la modification d'un bail.

/// Bascule « durée indéterminée » : masque la date de fin.
class InterrupteurDuree extends StatelessWidget {
  final bool valeur;
  final ValueChanged<bool> onChanged;

  const InterrupteurDuree({super.key, required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: valeur ? AppColors.primaryTint : AppColors.cardTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!valeur),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.all_inclusive_rounded, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durée indéterminée',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valeur ? 'Le bail court jusqu\'à résiliation' : 'Le bail prend fin à la date indiquée',
                      style: TextStyle(fontSize: 12, color: AppColors.label),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: valeur,
                activeTrackColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aperçu du premier loyer facturé et de l'avance à encaisser à la signature.
class PremierLoyer extends StatelessWidget {
  final DateTime? premierMois;
  final int moisAvance;
  final double montantAvance;

  const PremierLoyer({
    super.key,
    required this.premierMois,
    required this.moisAvance,
    required this.montantAvance,
    this.titre = 'Premier loyer facturé',
  });

  /// Libellé de l'aperçu ; « Premier loyer facturé » par défaut.
  final String titre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: TextStyle(fontSize: 12, color: AppColors.label)),
                if (moisAvance > 0)
                  Text('Avance à la signature : ${formatMontant(montantAvance)}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.label)),
              ],
            ),
          ),
          Text(
            formatMois(premierMois),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark),
          ),
        ],
      ),
    );
  }
}

/// Dépôt de garantie déduit du loyer et du nombre de mois de caution.
class DepotCalcule extends StatelessWidget {
  final double? montant;
  final int? mois;

  const DepotCalcule({super.key, required this.montant, required this.mois});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, size: 20, color: AppColors.positive),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dépôt de garantie', style: TextStyle(fontSize: 12, color: AppColors.label)),
                if (mois != null && mois! > 0)
                  Text('$mois mois × loyer', style: TextStyle(fontSize: 11.5, color: AppColors.label)),
              ],
            ),
          ),
          Text(
            formatMontant(montant),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark),
          ),
        ],
      ),
    );
  }
}
