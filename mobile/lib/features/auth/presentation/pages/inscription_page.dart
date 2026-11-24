import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_ui.dart';

/// Création d'un compte organisation en libre-service : l'agence (ou le
/// bailleur) et son propriétaire. L'essai gratuit démarre aussitôt et la
/// session s'ouvre directement.
class InscriptionPage extends ConsumerStatefulWidget {
  const InscriptionPage({super.key});

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends ConsumerState<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _organisation = TextEditingController();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _motDePasse = TextEditingController();
  final _confirmation = TextEditingController();
  bool _masque = true;
  bool _envoi = false;
  String? _erreur;
  int _tick = 0;

  static final _emailValide = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _telephoneValide = RegExp(r'^\+?[0-9 .\-()]{8,20}$');

  @override
  void dispose() {
    for (final c in [_organisation, _prenom, _nom, _email, _telephone, _motDePasse, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _creer() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final erreur = await ref.read(authNotifierProvider.notifier).inscrire(
          organisation: _organisation.text,
          prenom: _prenom.text,
          nom: _nom.text,
          email: _email.text,
          telephone: _telephone.text,
          motDePasse: _motDePasse.text,
        );
    // En cas de succès, l'application redémarre sur la session ouverte.
    if (!mounted || erreur == null) return;
    setState(() {
      _envoi = false;
      _erreur = erreur;
      _tick++;
    });
  }

  String? _obligatoire(String? v, String quoi) => v == null || v.trim().isEmpty ? '$quoi obligatoire.' : null;

  String? _robustesse(String? v) {
    if (v == null || v.length < 8) return 'Au moins 8 caractères.';
    if (!v.contains(RegExp(r'[A-Za-z]')) || !v.contains(RegExp(r'\d'))) {
      return 'Au moins une lettre et un chiffre.';
    }
    return null;
  }

  Widget _champ(TextEditingController c, String label, IconData icone,
          {String? Function(String?)? validator,
          TextInputType? clavier,
          bool masque = false,
          Widget? suffixe,
          TextCapitalization majuscules = TextCapitalization.none}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          keyboardType: clavier,
          obscureText: masque,
          autocorrect: false,
          textCapitalization: majuscules,
          textInputAction: TextInputAction.next,
          decoration: authInputDecoration(label: label, icon: icone, suffixIcon: suffixe),
          validator: validator,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final oeil = IconButton(
      icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kAuthHint, size: 20),
      onPressed: () => setState(() => _masque = !_masque),
    );
    return AuthScaffold(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthBrand(
              assetLogo: 'assets/images/logo_tmk.png',
              compact: true,
              subtitle: 'Créez l\'espace de votre agence en une minute',
            ),
            const SizedBox(height: 16),
            const _AtoutsEssai(),
            const SizedBox(height: 20),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthMessage(message: _erreur, tick: _tick),
                  const _Rubrique('Votre organisation'),
                  _champ(_organisation, 'Nom de l\'agence ou du bailleur', Icons.business_rounded,
                      majuscules: TextCapitalization.words,
                      validator: (v) => _obligatoire(v, 'Nom')),
                  const _Rubrique('Vous'),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: _champ(_prenom, 'Prénom', Icons.person_outline_rounded,
                          majuscules: TextCapitalization.words, validator: (v) => _obligatoire(v, 'Prénom')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _champ(_nom, 'Nom', Icons.badge_outlined,
                          majuscules: TextCapitalization.words, validator: (v) => _obligatoire(v, 'Nom')),
                    ),
                  ]),
                  _champ(_telephone, 'Téléphone', Icons.phone_outlined,
                      clavier: TextInputType.phone,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Téléphone obligatoire : c\'est votre identifiant.';
                        return _telephoneValide.hasMatch(t) ? null : 'Numéro invalide (ex. 07 07 12 34 56).';
                      }),
                  _champ(_email, 'Adresse e-mail (facultatif)', Icons.alternate_email_rounded,
                      clavier: TextInputType.emailAddress,
                      validator: (v) {
                        final e = (v ?? '').trim();
                        return e.isEmpty || _emailValide.hasMatch(e) ? null : 'Adresse e-mail invalide.';
                      }),
                  _champ(_motDePasse, 'Mot de passe', Icons.lock_outline_rounded,
                      masque: _masque, suffixe: oeil, validator: _robustesse),
                  _champ(_confirmation, 'Confirmer le mot de passe', Icons.lock_reset_rounded,
                      masque: _masque,
                      validator: (v) => v != _motDePasse.text ? 'Les mots de passe diffèrent.' : null),
                  const SizedBox(height: 6),
                  AuthPrimaryButton(
                    label: 'Créer mon compte',
                    icon: Icons.rocket_launch_outlined,
                    loading: _envoi,
                    onPressed: _envoi ? null : _creer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'En créant un compte, vous acceptez les conditions d\'utilisation du service. '
                    'Votre numéro de téléphone sera votre identifiant de connexion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, height: 1.4, color: kAuthHint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text.rich(TextSpan(
                text: 'Déjà un compte ? ',
                style: TextStyle(color: kAuthHint, fontSize: 13.5),
                children: [
                  TextSpan(
                    text: 'Se connecter',
                    style: TextStyle(color: kAuthPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rubrique extends StatelessWidget {
  final String titre;
  const _Rubrique(this.titre);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Text(titre.toUpperCase(),
            style: TextStyle(
                fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: AppColors.label)),
      );
}

/// Ce que l'essai apporte, en trois pastilles.
class _AtoutsEssai extends StatelessWidget {
  const _AtoutsEssai();

  @override
  Widget build(BuildContext context) {
    Widget pastille(IconData icone, String texte) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icone, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(texte,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ]),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        pastille(Icons.card_giftcard_rounded, '30 jours offerts'),
        pastille(Icons.credit_card_off_outlined, 'Sans carte bancaire'),
        pastille(Icons.groups_2_outlined, 'Jusqu\'à 10 collaborateurs'),
      ],
    );
  }
}
