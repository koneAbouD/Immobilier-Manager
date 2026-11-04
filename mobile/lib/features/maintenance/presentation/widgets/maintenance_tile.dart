import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../domain/entities/maintenance.dart';

class MaintenanceTile extends StatelessWidget {
  final Maintenance maintenance;
  final VoidCallback onTap;

  const MaintenanceTile({super.key, required this.maintenance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = maintenance;
    final date = m.datePrevue != null && m.statut.estOuverte
        ? 'Prévue le ${formatDate(m.datePrevue)}'
        : 'Signalée le ${formatDate(m.dateSignalement)}';
    final urgente =
        m.priorite == PrioriteMaintenance.urgente && m.statut.estOuverte;
    return ListeCarte(
      icon: m.categorie.icone,
      couleur: m.priorite.couleur,
      titre: m.titre,
      valeur: urgente ? 'URGENT' : null,
      sousTitre: m.localisation,
      detail: date,
      badge: PastilleStatut(m.statut.libelle, m.statut.couleur),
      onTap: onTap,
    );
  }
}
