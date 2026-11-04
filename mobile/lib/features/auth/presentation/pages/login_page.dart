import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_ui.dart';

/// Connexion, au gabarit des écrans d'accès de VTC Manager : logo TMK, carte
/// blanche, bandeau de message qui reste sous les yeux, bouton dégradé.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _masque = true;

  /// Incrémenté à chaque nouveau refus, pour que deux échecs identiques se
  /// voient (secousse) au lieu de laisser le bandeau immobile.
  int _errorTick = 0;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref.read(authNotifierProvider.notifier).login(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final loading = state is AuthLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthError) {
        // Seul le mot de passe est effacé : faire retaper l'identifiant après
        // une faute de frappe n'apporte rien.
        _password.clear();
        _passwordFocus.requestFocus();
        setState(() => _errorTick++);
      }
    });

    final (message, type) = switch (state) {
      AuthError(:final message) => (message, AuthToastType.error),
      AuthUnauthenticated(:final message) => (message, AuthToastType.info),
      _ => (null, AuthToastType.error),
    };

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthBrand(
              assetLogo: 'assets/images/logo_tmk.png',
              subtitle: 'Gérez votre patrimoine locatif en toute simplicité',
            ),
            const SizedBox(height: 32),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthMessage(message: message, type: type, tick: _errorTick),
                  TextFormField(
                    controller: _username,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      label: 'Identifiant',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Identifiant obligatoire.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    obscureText: _masque,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: authInputDecoration(
                      label: 'Mot de passe',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _masque
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: kAuthHint,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _masque = !_masque),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Mot de passe obligatoire.' : null,
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Se connecter',
                    loading: loading,
                    onPressed: loading ? null : _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Immobilier Manager · TMK',
                style: TextStyle(color: kAuthHint, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
