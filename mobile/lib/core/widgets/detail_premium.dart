import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Briques d'interface « premium » reprises de VTC Manager (page Apparence,
/// feuille d'encaissement) : surfaces arrondies, bordures fines, pastilles
/// d'icône teintées et hiérarchie typographique nette.

/// Carte-section : en-tête (icône teintée + titre) puis lignes. La section
/// disparaît si toutes ses lignes sont vides (`PremiumRow` masqués).
class PremiumSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color accent;

  PremiumSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    Color? accent,
  }) : accent = accent ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    if (children.every((w) => w is SizedBox)) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark)),
          ]),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// Ligne label / valeur. Se masque si la valeur est nulle ou vide.
class PremiumRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool strong;
  final Color? valueColor;

  const PremiumRow(this.label, this.value,
      {super.key, this.strong = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 12.5, color: AppColors.label)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value!,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                    color: valueColor ?? AppColors.dark)),
          ),
        ],
      ),
    );
  }
}

/// Puce de statut colorée.
class PremiumChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const PremiumChip(this.label, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

/// Titre d'une liste (« Encaissements (2) »).
class PremiumListHeader extends StatelessWidget {
  final String title;
  const PremiumListHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
    );
  }
}

/// Tuile d'un encaissement : pastille + montant + mode·date·réf, et le
/// commentaire de saisie s'il existe.
///
/// Un versement extourné (`annule`) reste affiché — il a bien eu lieu — mais
/// son montant est barré et son motif rappelé : il ne compte plus dans ce que
/// la ligne a encaissé, et rien ne doit laisser croire le contraire.
///
/// La date du versement peut être corrigée quand le serveur le permet
/// ([onModifierDate] non nul) : un bouton de date apparaît au bord de la tuile.
/// Quand il ne le permet plus, un cadenas prend sa place et dit pourquoi sous
/// un appui long — sauf sur un versement extourné, où le badge « Annulé » a
/// déjà tout dit.
/// Bouton d'action pleine largeur. `filled` → plein coloré ; sinon contour.
/// `expanded` : supprime la largeur/marge propres pour l'insérer dans une Row
/// (via [PremiumButtonRow]).
class PremiumButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final bool expanded;
  final VoidCallback onPressed;

  PremiumButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    Color? color,
    this.filled = true,
    this.expanded = false,
  }) : color = color ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 50,
      width: expanded ? null : double.infinity,
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(icon, size: 18),
              label: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(icon, size: 18),
              label: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
    );
    if (expanded) return button;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: button);
  }
}

/// Dispose deux (ou plus) [PremiumButton] `expanded` sur une même ligne, de
/// largeur égale.
class PremiumButtonRow extends StatelessWidget {
  final List<PremiumButton> buttons;
  const PremiumButtonRow({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < buttons.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 12));
      children.add(Expanded(child: buttons[i]));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: children),
    );
  }
}
