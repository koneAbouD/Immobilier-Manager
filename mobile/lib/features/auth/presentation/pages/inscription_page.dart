import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_ui.dart';

/// Création d'un compte organisation en libre-service : l'agence (ou le
/// bailleur) et son propriétaire. L'essai gratuit démarre aussitôt et la
/// session s'ouvre directement.
///
/// Conçue pour tenir sur un écran sans défiler : en-tête compact, champs
/// resserrés, et deux colonnes dès que la largeur le permet (téléphone pliant
/// ouvert, tablette). Le défilement ne reste qu'en secours, clavier ouvert ou
/// très petit écran.
class InscriptionPage extends ConsumerStatefulWidget {
  const InscriptionPage({super.key});

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends ConsumerState<InscriptionPage> {
  /// Largeur à partir de laquelle les champs vont deux par ligne.
  static const _largeurDeuxColonnes = 600.0;

  final _formKey = GlobalKey<FormState>();
  final _organisation = TextEditingController();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _masque = true;
  bool _envoi = false;
  String? _erreur;
  int _tick = 0;

  static final _emailValide = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _telephoneValide = RegExp(r'^\+?[0-9 .\-()]{8,20}$');

  @override
  void dispose() {
    for (final c in [_organisation, _prenom, _nom, _telephone, _email, _motDePasse]) {
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
    // En cas de succès, la session est ouverte et le choix du code TMK prend
    // la place de cette page.
    if (!mounted || erreur == null) return;
    setState(() {
      _envoi = false;
      _erreur = erreur;
      _tick++;
    });
  }

  String? _obligatoire(String? v, String quoi) => v == null || v.trim().isEmpty ? '$quoi obligatoire.' : null;

  String? _verifierTelephone(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Téléphone obligatoire.';
    return _telephoneValide.hasMatch(t) ? null : 'Numéro invalide (ex. 07 07 12 34 56).';
  }

  String? _verifierEmail(String? v) {
    final e = (v ?? '').trim();
    return e.isEmpty || _emailValide.hasMatch(e) ? null : 'Adresse e-mail invalide.';
  }

  String? _verifierMotDePasse(String? v) {
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
          TextInputAction action = TextInputAction.next,
          ValueChanged<String>? onSubmitted,
          TextCapitalization majuscules = TextCapitalization.none}) =>
      TextFormField(
        controller: c,
        keyboardType: clavier,
        obscureText: masque,
        autocorrect: false,
        textCapitalization: majuscules,
        textInputAction: action,
        onFieldSubmitted: onSubmitted,
        decoration: authInputDecoration(label: label, icon: icone, suffixIcon: suffixe, compact: true),
        validator: validator,
      );

  /// Deux champs côte à côte.
  Widget _paire(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ]);

  List<Widget> _lignes(bool large) {
    final organisation = _champ(_organisation, 'Nom de l\'agence ou du bailleur', Icons.business_rounded,
        majuscules: TextCapitalization.words, validator: (v) => _obligatoire(v, 'Nom'));
    final prenom = _champ(_prenom, 'Prénom', Icons.person_outline_rounded,
        majuscules: TextCapitalization.words, validator: (v) => _obligatoire(v, 'Prénom'));
    final nom = _champ(_nom, 'Nom', Icons.badge_outlined,
        majuscules: TextCapitalization.words, validator: (v) => _obligatoire(v, 'Nom'));
    final telephone = _champ(_telephone, 'Téléphone (identifiant)', Icons.phone_outlined,
        clavier: TextInputType.phone, validator: _verifierTelephone);
    final email = _champ(_email, 'E-mail (facultatif)', Icons.alternate_email_rounded,
        clavier: TextInputType.emailAddress, validator: _verifierEmail);
    final motDePasse = _champ(_motDePasse, 'Mot de passe', Icons.lock_outline_rounded,
        masque: _masque,
        action: TextInputAction.done,
        onSubmitted: (_) => _creer(),
        validator: _verifierMotDePasse,
        suffixe: IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: _masque ? 'Afficher' : 'Masquer',
          icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kAuthHint, size: 20),
          onPressed: () => setState(() => _masque = !_masque),
        ));
    return large
        ? [_paire(organisation, telephone), _paire(prenom, nom), _paire(email, motDePasse)]
        : [organisation, _paire(prenom, nom), telephone, email, motDePasse];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, contraintes) {
          final large = contraintes.maxWidth >= _largeurDeuxColonnes;
          final lignes = _lignes(large);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ConstrainedBox(
              // Centré verticalement quand tout tient, défilable sinon.
              constraints: BoxConstraints(minHeight: contraintes.maxHeight - 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: large ? 720 : 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Entete(),
                        const SizedBox(height: 14),
                        AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthMessage(message: _erreur, tick: _tick, margin: const EdgeInsets.only(bottom: 12)),
                              for (var i = 0; i < lignes.length; i++) ...[
                                if (i > 0) const SizedBox(height: 10),
                                lignes[i],
                              ],
                              const SizedBox(height: 16),
                              AuthPrimaryButton(
                                label: 'Créer mon compte',
                                icon: Icons.rocket_launch_outlined,
                                loading: _envoi,
                                onPressed: _envoi ? null : _creer,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'En créant un compte, vous acceptez les conditions d\'utilisation du service.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, height: 1.3, color: kAuthHint),
                              ),
                            ],
                          ),
                        ),
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
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// En-tête compact : retour, logo, titre et promesse de l'essai, sur une ligne.
class _Entete extends StatelessWidget {
  const _Entete();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.arrow_back_rounded, color: kAuthDark),
        style: IconButton.styleFrom(backgroundColor: AppColors.blanc),
        tooltip: 'Retour',
      ),
      const SizedBox(width: 8),
      Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.blanc, borderRadius: BorderRadius.circular(14)),
        child: Image.asset('assets/images/logo_tmk.png', fit: BoxFit.contain),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Créer votre espace',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kAuthDark, letterSpacing: -0.3)),
          const SizedBox(height: 3),
          Row(children: [
            Icon(Icons.card_giftcard_rounded, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 5),
            Flexible(
              child: Text('Essai gratuit de 30 jours, sans engagement',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            ),
          ]),
        ]),
      ),
    ]);
  }
}
