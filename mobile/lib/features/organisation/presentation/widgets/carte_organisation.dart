import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/organisation.dart';

/// Monogramme d'une organisation : initiales sur fond teinté.
class MonogrammeOrganisation extends StatelessWidget {
  final String nom;
  final double taille;

  const MonogrammeOrganisation(this.nom, {super.key, this.taille = 44});

  String get _initiales {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, mots.first.length.clamp(1, 2)).toUpperCase();
    return (mots[0][0] + mots[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: taille,
        height: taille,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(taille * 0.3),
        ),
        child: Text(_initiales,
            style: TextStyle(
                fontSize: taille * 0.36, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
      );
}

/// Pastille de rôle.
class PastilleRole extends StatelessWidget {
  final RoleMembre role;
  const PastilleRole(this.role, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: role.couleur.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(role.icone, size: 12, color: role.couleur),
          const SizedBox(width: 4),
          Text(role.libelle,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: role.couleur)),
        ]),
      );
}

/// Ligne d'organisation du sélecteur.
class CarteOrganisation extends StatelessWidget {
  final Adhesion adhesion;
  final bool active;
  final VoidCallback onTap;

  const CarteOrganisation({super.key, required this.adhesion, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final bloquee = adhesion.acces == AccesOrganisation.bloque;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: bloquee ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: active ? AppColors.primary : AppColors.border, width: active ? 1.6 : 1),
            ),
            child: Row(children: [
              MonogrammeOrganisation(adhesion.organisation),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(adhesion.organisation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: bloquee ? AppColors.hint : AppColors.dark)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    PastilleRole(adhesion.role),
                    if (adhesion.statut != StatutAbonnement.actif)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: adhesion.statut.couleur.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(adhesion.statut.libelle,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: adhesion.statut.couleur)),
                      ),
                  ]),
                ]),
              ),
              Icon(active ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  color: active ? AppColors.primary : AppColors.hint),
            ]),
          ),
        ),
      ),
    );
  }
}
