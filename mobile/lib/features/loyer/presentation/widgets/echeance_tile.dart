import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../domain/entities/echeance.dart';

class EcheanceTile extends StatelessWidget {
  final Echeance echeance;
  final bool afficherLocataire;
  final VoidCallback onTap;

  const EcheanceTile({
    super.key,
    required this.echeance,
    required this.onTap,
    this.afficherLocataire = true,
  });

  @override
  Widget build(BuildContext context) {
    final e = echeance;
    final couleur = e.enRetard ? AppColors.error : e.statut.couleur;
    final partiel = e.montantPaye > 0 && e.resteDu > 0;
    return ListeCarte(
      icon: e.statut == StatutEcheance.payee
          ? Icons.check_rounded
          : e.enRetard
              ? Icons.priority_high_rounded
              : Icons.receipt_long_outlined,
      couleur: couleur,
      titre: afficherLocataire ? e.locataireNom : formatMois(e.periode),
      valeur: formatMontant(e.encaissable ? e.resteDu : e.montantDu),
      sousTitre: afficherLocataire
          ? '${formatMois(e.periode)} · ${e.logement}'
          : 'Échéance le ${formatDate(e.dateEcheance)}',
      detail: partiel ? 'Payé ${formatMontant(e.montantPaye)}' : null,
      badge: PastilleStatut(e.enRetard ? 'En retard' : e.statut.libelle, couleur),
      onTap: onTap,
    );
  }
}
