import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Forme commune des boîtes de dialogue : coins larges, boutons pleine largeur
/// côte à côte, comme dans VTC Manager.
ShapeBorder get _forme =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

TextStyle get _titre => TextStyle(
    fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark);

/// Boutons « Annuler / Valider » d'une boîte de dialogue.
List<Widget> _boutons({
  required String retour,
  required VoidCallback onRetour,
  required String action,
  required VoidCallback onAction,
  bool destructive = false,
}) =>
    [
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onRetour,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dark,
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(retour),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? AppColors.error : null,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(action, textAlign: TextAlign.center),
          ),
        ),
      ]),
    ];

/// Demande une confirmation avant une action irréversible.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String action = 'Confirmer',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: _forme,
      title: Text(titre, style: _titre),
      content: Text(message,
          style: TextStyle(fontSize: 14, color: AppColors.label, height: 1.4)),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: _boutons(
        retour: 'Annuler',
        onRetour: () => Navigator.pop(ctx, false),
        action: action,
        onAction: () => Navigator.pop(ctx, true),
        destructive: destructive,
      ),
    ),
  );
  return ok ?? false;
}

/// Saisie d'un motif obligatoire (annulation, résiliation).
/// Renvoie null si l'utilisateur renonce.
Future<String?> demanderMotif(
  BuildContext context, {
  required String titre,
  String libelle = 'Motif',
  String action = 'Valider',
}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: _forme,
      title: Text(titre, style: _titre),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: libelle),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Le motif est obligatoire.' : null,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: _boutons(
        retour: 'Retour',
        onRetour: () => Navigator.pop(ctx),
        action: action,
        onAction: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(ctx, controller.text.trim());
          }
        },
        destructive: true,
      ),
    ),
  );
}

/// Contenu personnalisé (ex. coût réel d'une intervention) dans la même boîte
/// que [confirmer]. Renvoie vrai si l'utilisateur valide.
Future<bool> dialogueSaisie(
  BuildContext context, {
  required String titre,
  required Widget contenu,
  String action = 'Valider',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: _forme,
      title: Text(titre, style: _titre),
      content: contenu,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: _boutons(
        retour: 'Retour',
        onRetour: () => Navigator.pop(ctx, false),
        action: action,
        onAction: () => Navigator.pop(ctx, true),
      ),
    ),
  );
  return ok ?? false;
}
