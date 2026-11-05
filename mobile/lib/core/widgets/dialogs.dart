import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'form_fields.dart';

/// Boîtes de dialogue au gabarit de VTC Manager : coins de 20, icône dans une
/// tuile teintée à gauche du titre, texte gris, puis « Annuler » en contour et
/// l'action en plein, alignés à droite.

ShapeBorder get _forme => RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

/// Titre d'une boîte : tuile d'icône teintée et libellé.
Widget _titre(String titre, IconData icone, Color couleur) => Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icone, color: couleur, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(titre,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark)),
      ),
    ]);

Text _message(String message) =>
    Text(message, style: TextStyle(fontSize: 13.5, color: AppColors.grey600, height: 1.4));

Widget _boutonRetour(String libelle, VoidCallback onPressed) => OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: AppColors.border),
        foregroundColor: AppColors.noir87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(libelle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );

Widget _boutonAction(String libelle, VoidCallback? onPressed, {bool destructive = false}) => FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: destructive ? AppColors.error : null,
        disabledBackgroundColor: (destructive ? AppColors.error : AppColors.primary).withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(libelle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );

const _contentPadding = EdgeInsets.fromLTRB(24, 16, 24, 16);
const _actionsPadding = EdgeInsets.fromLTRB(16, 0, 16, 16);

/// Demande une confirmation avant une action irréversible.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String action = 'Confirmer',
  bool destructive = false,
  IconData? icone,
}) async {
  final couleur = destructive ? AppColors.error : AppColors.primary;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: _forme,
      title: _titre(
          titre, icone ?? (destructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded), couleur),
      contentPadding: _contentPadding,
      content: _message(message),
      actionsPadding: _actionsPadding,
      actions: [
        _boutonRetour('Annuler', () => Navigator.pop(ctx, false)),
        _boutonAction(action, () => Navigator.pop(ctx, true), destructive: destructive),
      ],
    ),
  );
  return ok ?? false;
}

/// Saisie d'un motif obligatoire (annulation, résiliation) : l'action reste
/// inactive tant que le motif est vide. Renvoie null si l'utilisateur renonce.
Future<String?> demanderMotif(
  BuildContext context, {
  required String titre,
  String libelle = 'Motif',
  String action = 'Valider',
  String? message,
  String hint = 'Précisez le motif…',
}) async {
  final controller = TextEditingController();
  final motif = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        shape: _forme,
        title: _titre(titre, Icons.edit_note_rounded, AppColors.error),
        contentPadding: _contentPadding,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[_message(message), const SizedBox(height: 16)],
            EtiquetteChamp(libelle, obligatoire: true),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              style: TextStyle(fontSize: 14, color: AppColors.dark),
              decoration: decorationPilule(hint: hint),
              onChanged: (_) => setLocal(() {}),
            ),
          ],
        ),
        actionsPadding: _actionsPadding,
        actions: [
          _boutonRetour('Retour', () => Navigator.pop(ctx)),
          _boutonAction(
            action,
            controller.text.trim().isEmpty ? null : () => Navigator.pop(ctx, controller.text.trim()),
            destructive: true,
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return motif;
}

/// Contenu personnalisé (ex. coût réel d'une intervention) dans la même boîte
/// que [confirmer]. Renvoie vrai si l'utilisateur valide.
Future<bool> dialogueSaisie(
  BuildContext context, {
  required String titre,
  required Widget contenu,
  String action = 'Valider',
  IconData icone = Icons.edit_outlined,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: _forme,
      title: _titre(titre, icone, AppColors.primary),
      contentPadding: _contentPadding,
      content: contenu,
      actionsPadding: _actionsPadding,
      actions: [
        _boutonRetour('Retour', () => Navigator.pop(ctx, false)),
        _boutonAction(action, () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return ok ?? false;
}

/// Boîte d'information à un seul bouton « Fermer ».
Future<void> informer(
  BuildContext context, {
  required String titre,
  required String message,
  IconData icone = Icons.info_outline_rounded,
}) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: _forme,
        title: _titre(titre, icone, AppColors.info),
        contentPadding: _contentPadding,
        content: _message(message),
        actionsPadding: _actionsPadding,
        actions: [_boutonAction('Fermer', () => Navigator.pop(ctx))],
      ),
    );

/// Feuille du bas au gabarit de VTC Manager : fond blanc, coins de 24,
/// poignée de glissement.
Future<T?> afficherFeuille<T>(BuildContext context, {required WidgetBuilder builder}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.blanc,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        ),
        Flexible(child: builder(ctx)),
      ]),
    );

/// En-tête d'une feuille du bas : tuile d'icône teintée, titre et sous-titre.
class EnteteFeuille extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? sousTitre;
  final Widget? trailing;
  final Color? couleur;

  const EnteteFeuille({
    super.key,
    required this.icone,
    required this.titre,
    this.sousTitre,
    this.trailing,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final accent = couleur ?? AppColors.primary;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icone, color: accent, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titre,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark, letterSpacing: -0.3)),
          if (sousTitre != null) ...[
            const SizedBox(height: 2),
            Text(sousTitre!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: AppColors.label)),
          ],
        ]),
      ),
      ?trailing,
    ]);
  }
}
