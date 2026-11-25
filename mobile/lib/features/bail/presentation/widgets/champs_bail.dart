import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/bail.dart';

// Éléments communs à la signature et à la modification d'un bail.

/// Bascule « durée indéterminée » : masque la date de fin.
class InterrupteurDuree extends StatelessWidget {
  final bool valeur;
  final ValueChanged<bool> onChanged;

  const InterrupteurDuree({super.key, required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) => _Interrupteur(
    icone: Icons.all_inclusive_rounded,
    titre: 'Durée indéterminée',
    detail: valeur ? 'Le bail court jusqu\'à résiliation' : 'Le bail prend fin à la date indiquée',
    valeur: valeur,
    onChanged: onChanged,
  );
}

/// Bail externe : le recouvrement des loyers est assuré par une autre entité,
/// l'application n'en émet aucun.
class InterrupteurBailExterne extends StatelessWidget {
  final bool valeur;

  /// Nul : interrupteur figé (délai de changement dépassé).
  final ValueChanged<bool>? onChanged;

  /// Remplace le texte d'aide, par exemple pour expliquer un blocage.
  final String? detail;

  const InterrupteurBailExterne({super.key, required this.valeur, required this.onChanged, this.detail});

  @override
  Widget build(BuildContext context) => _Interrupteur(
    icone: Icons.handshake_outlined,
    titre: 'Bail externe',
    detail:
        detail ??
        (valeur
            ? 'Loyers recouvrés par une autre entité : aucun loyer ne sera généré'
            : 'Les loyers sont générés et suivis dans l\'application'),
    valeur: valeur,
    onChanged: onChanged,
  );
}

class _Interrupteur extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String detail;
  final bool valeur;
  final ValueChanged<bool>? onChanged;

  const _Interrupteur({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.valeur,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: valeur ? AppColors.primaryTint : AppColors.cardTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onChanged == null ? null : () => onChanged!(!valeur),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Icon(icone, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                    const SizedBox(height: 2),
                    Text(detail, style: TextStyle(fontSize: 12, color: AppColors.label)),
                  ],
                ),
              ),
              Switch.adaptive(value: valeur, activeTrackColor: AppColors.primary, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Choix du régime du bail (habitation ou professionnel) : deux tuiles côte à
/// côte. Il fixe le modèle du contrat PDF.
class ChoixUsageBail extends StatelessWidget {
  final UsageBail valeur;
  final ValueChanged<UsageBail> onChanged;

  const ChoixUsageBail({super.key, required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final u in UsageBail.values) ...[
          if (u.index > 0) const SizedBox(width: 10),
          Expanded(child: _TuileUsage(usage: u, choisi: u == valeur, onTap: () => onChanged(u))),
        ],
      ],
    );
  }
}

class _TuileUsage extends StatelessWidget {
  final UsageBail usage;
  final bool choisi;
  final VoidCallback onTap;

  const _TuileUsage({required this.usage, required this.choisi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: choisi,
      button: true,
      child: Material(
        color: choisi ? AppColors.primaryTint : AppColors.cardTint,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: choisi ? AppColors.primary : AppColors.border,
                width: choisi ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(usage.icone, size: 20, color: AppColors.primaryDark),
                    const Spacer(),
                    Icon(
                      choisi ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: choisi ? AppColors.primary : AppColors.hint,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  usage.libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                ),
                const SizedBox(height: 2),
                Text(usage.detail, style: TextStyle(fontSize: 11.5, color: AppColors.label)),
              ],
            ),
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
                  Text(
                    'Avance à la signature : ${formatMontant(montantAvance)}',
                    style: TextStyle(fontSize: 11.5, color: AppColors.label),
                  ),
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

/// Ligne d'aide sous le dépôt de garantie : d'où vient le montant, et un lien
/// pour revenir au calcul quand il a été saisi à la main.
class AideDepot extends StatelessWidget {
  final int? mois;
  final double? calcul;

  /// Montant saisi à la main, différent du calcul.
  final bool libre;
  final VoidCallback onRecalculer;

  const AideDepot({
    super.key,
    required this.mois,
    required this.calcul,
    required this.libre,
    required this.onRecalculer,
  });

  @override
  Widget build(BuildContext context) {
    // Même retrait et même style que le texte d'aide des autres champs.
    final style = TextStyle(fontSize: 11.5, color: AppColors.hint);
    if (!libre) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 16),
        child: Text(
          mois == null || mois == 0 ? 'Aucune caution' : '$mois mois × loyer · modifiable',
          style: style,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 16),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Expanded(child: Text('Montant libre', maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          if (calcul != null)
            TextButton(
              onPressed: onRecalculer,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Recalculer : ${formatMontant(calcul)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
