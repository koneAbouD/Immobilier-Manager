import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../providers/organisation_providers.dart';
import '../../../../core/utils/insets_systeme.dart';

/// Changement de mot de passe, sur présentation de l'actuel.
class MotDePassePage extends ConsumerStatefulWidget {
  const MotDePassePage({super.key});

  @override
  ConsumerState<MotDePassePage> createState() => _MotDePassePageState();
}

class _MotDePassePageState extends ConsumerState<MotDePassePage> {
  final _formKey = GlobalKey<FormState>();
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _masque = true;
  bool _envoi = false;

  @override
  void dispose() {
    for (final c in [_actuel, _nouveau, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final result = await ref.read(organisationRepositoryProvider).changerMotDePasse(_actuel.text, _nouveau.text);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Mot de passe modifié.');
      Navigator.pop(context);
    });
  }

  Widget _champ(TextEditingController c, String label, String? Function(String?) validator) => ChampEtiquete(
        label: label,
        obligatoire: true,
        child: TextFormField(
          controller: c,
          obscureText: _masque,
          autocorrect: false,
          style: TextStyle(fontSize: 15, color: AppColors.dark),
          decoration: decorationPilule(
            hint: label,
            suffixIcon: IconButton(
              icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: AppColors.hint),
              onPressed: () => setState(() => _masque = !_masque),
            ),
          ),
          validator: validator,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: 'Mot de passe'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + context.basSysteme),
          children: [
            GroupeChamps(titre: 'Changer de mot de passe', icone: Icons.lock_reset_rounded, children: [
              _champ(_actuel, 'Mot de passe actuel', (v) => v == null || v.isEmpty ? 'Champ obligatoire.' : null),
              kGapChamps,
              _champ(_nouveau, 'Nouveau mot de passe', (v) {
                if (v == null || v.length < 8) return 'Au moins 8 caractères.';
                if (!v.contains(RegExp(r'[A-Za-z]')) || !v.contains(RegExp(r'\d'))) {
                  return 'Au moins une lettre et un chiffre.';
                }
                return null;
              }),
              kGapChamps,
              _champ(_confirmation, 'Confirmation',
                  (v) => v != _nouveau.text ? 'Les mots de passe diffèrent.' : null),
            ]),
            BoutonPrincipal(label: 'Enregistrer', icon: Icons.check_rounded, loading: _envoi, onPressed: _valider),
          ],
        ),
      ),
    );
  }
}
