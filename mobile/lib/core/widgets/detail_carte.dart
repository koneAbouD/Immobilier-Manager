import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Briques d'une page de détail, reprises de VTC Manager : une carte d'en-tête
/// qui nomme l'objet et son statut, puis des cartes où les couples
/// libellé/valeur se lisent d'un trait.
///
/// Toutes les pages de détail (immeuble, logement, locataire, bail,
/// intervention) les partagent pour se ressembler.

/// En-tête : pastille colorée, libellé de l'objet (et sa ligne de contexte),
/// badge de statut poussé au bord droit.
class DetailHeroCard extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String? sousTitre;
  final String? statutLabel;
  final Color? statutColor;

  /// Teinte de la pastille quand elle ne doit pas suivre le statut.
  final Color? iconColor;

  const DetailHeroCard({
    super.key,
    required this.icon,
    required this.titre,
    this.sousTitre,
    this.statutLabel,
    this.statutColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final teinte = iconColor ?? statutColor ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: teinte.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: teinte, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      letterSpacing: -0.3),
                ),
                if (sousTitre != null && sousTitre!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sousTitre!,
                      style: TextStyle(fontSize: 12.5, color: AppColors.label)),
                ],
              ],
            ),
          ),
          if (statutLabel != null) ...[
            const SizedBox(width: 12),
            StatutBadge(statutLabel!, statutColor ?? AppColors.primary),
          ],
        ],
      ),
    );
  }
}

/// Badge de statut rectangulaire des en-têtes et des tuiles de liste.
class StatutBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatutBadge(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Carte des rubriques : la marge appartient à la carte, ses enfants ne font
/// que se suivre. Un [titre] facultatif ouvre la carte (icône à l'accent).
/// Le retrait bas est plus court que le haut, la dernière ligne apportant déjà
/// le sien.
class DetailInfoCard extends StatelessWidget {
  final String? titre;
  final IconData? icon;
  final List<Widget> children;

  const DetailInfoCard({
    super.key,
    this.titre,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titre != null) ...[
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(titre!,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark)),
            ]),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Ligne libellé/valeur. Se masque quand la valeur est nulle ou vide, ce qui
/// dispense l'appelant de conditionner chaque ligne.
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;

  const DetailInfoRow(this.icon, this.label, this.value,
      {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.label),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: AppColors.label)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value!,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre d'une sous-liste (« Logements », « Loyers »), au style des en-têtes
/// de liste de VTC Manager.
class SectionTitre extends StatelessWidget {
  final String titre;
  final Widget? action;

  const SectionTitre(this.titre, {super.key, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(titre,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark)),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Petit bouton texte teinté de l'accent (« + Ajouter »), posé à droite d'un
/// [SectionTitre] — le « Plus d'opérations » de l'accueil VTC.
class BoutonTexte extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const BoutonTexte(
      {super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon ?? Icons.add_rounded, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        backgroundColor: AppColors.primaryTint,
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
