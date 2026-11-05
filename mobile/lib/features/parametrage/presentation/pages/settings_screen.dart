import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../widgets/settings_tile.dart';
import 'apparence_page.dart';

const _kAppName = 'Immobilier Manager';
const _kAppVersion = '1.0.0';

/// Réglages, ouverts depuis le menu de l'accueil : bandeau d'identité,
/// configurations de l'application et déconnexion — sur le modèle de VTC
/// Manager.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _deconnecter(BuildContext context, WidgetRef ref) async {
    final ok = await confirmer(context,
        titre: 'Se déconnecter ?',
        message: 'Vous devrez saisir à nouveau vos identifiants.',
        action: 'Se déconnecter',
        destructive: true,
        icone: Icons.logout_rounded);
    if (ok) await ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final nom = auth is AuthAuthenticated ? auth.username : '';
    final apparence = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Réglages',
        backgroundColor: kSettingsHeaderFond,
        backButtonColor: AppColors.surface,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _BandeauProfil(nom: nom),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsCard(
                  fond: kSettingsHeaderFond,
                  children: [
                    SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'Apparence',
                      description: '${libelleModeTheme(apparence.mode)} · '
                          '${apparence.accent.libelle}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const ApparencePage()),
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'À propos',
                      description: 'Version $_kAppVersion',
                      onTap: () => _aPropos(context),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: _BoutonDeconnexion(
                      onTap: () => _deconnecter(context, ref)),
                ),
                const SizedBox(height: 16),
                Text('$_kAppName · TMK',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.hint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _aPropos(BuildContext context) {
    informer(context,
        titre: 'À propos',
        message: '$_kAppName - Gestion locative\n\nVersion $_kAppVersion\n\n© 2026 TMK');
  }
}

/// Bandeau d'identité : bloc plein dans la teinte de l'en-tête, seul son bord
/// bas est arrondi, comme dans VTC Manager.
class _BandeauProfil extends StatelessWidget {
  final String nom;

  const _BandeauProfil({required this.nom});

  @override
  Widget build(BuildContext context) {
    final initiale = nom.isEmpty ? '?' : nom.characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
      decoration: BoxDecoration(
        color: kSettingsHeaderFond,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Text(initiale,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom.isEmpty ? 'Gestionnaire' : nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                        letterSpacing: -0.2)),
                const SizedBox(height: 3),
                Text('Gestionnaire immobilier',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.label)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonDeconnexion extends StatelessWidget {
  final VoidCallback onTap;

  const _BoutonDeconnexion({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Flexible(
                child: Text('Se déconnecter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
