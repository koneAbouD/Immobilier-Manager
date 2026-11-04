import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tuile de liste au style des « dernières opérations » de VTC Manager :
/// surface blanche à ombre douce, pastille ronde teintée, titre et montant sur
/// la première ligne, contexte discret sur la seconde.
class ListeCarte extends StatelessWidget {
  final IconData? icon;

  /// Texte court à la place de l'icône (initiales d'un locataire).
  final String? initiales;
  final Color? couleur;
  final String titre;
  final String? sousTitre;

  /// Troisième ligne facultative (date, reste dû…).
  final String? detail;

  /// Valeur poussée à droite de la première ligne (montant).
  final String? valeur;

  /// Élément poussé à droite sous la valeur (badge de statut).
  final Widget? badge;

  /// Barre le titre et la valeur (paiement annulé).
  final bool barre;
  final VoidCallback? onTap;

  const ListeCarte({
    super.key,
    this.icon,
    this.initiales,
    this.couleur,
    required this.titre,
    this.sousTitre,
    this.detail,
    this.valeur,
    this.badge,
    this.barre = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teinte = couleur ?? AppColors.primaryDark;
    final decoration = barre ? TextDecoration.lineThrough : null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: teinte.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: initiales != null
                      ? Text(initiales!,
                          style: TextStyle(
                              color: teinte,
                              fontSize: 13,
                              fontWeight: FontWeight.w700))
                      : Icon(icon ?? Icons.circle_outlined,
                          color: teinte, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              titre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.dark,
                                  decoration: decoration),
                            ),
                          ),
                          if (valeur != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              valeur!,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.dark,
                                  decoration: decoration),
                            ),
                          ],
                        ],
                      ),
                      if (sousTitre != null && sousTitre!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          sousTitre!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11.5, color: AppColors.grey500),
                        ),
                      ],
                      if (detail != null || badge != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                detail ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.grey400),
                              ),
                            ),
                            ?badge,
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille de statut compacte des tuiles de liste.
class PastilleStatut extends StatelessWidget {
  final String label;
  final Color color;

  const PastilleStatut(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
