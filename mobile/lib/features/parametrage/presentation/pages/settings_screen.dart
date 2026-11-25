import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tmk_pin/tmk_pin.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/pin_setup_page.dart';
import '../../../organisation/domain/entities/organisation.dart';
import '../../../organisation/presentation/pages/abonnement_page.dart';
import '../../../organisation/presentation/pages/choix_organisation_page.dart';
import '../../../organisation/presentation/pages/equipe_page.dart';
import '../../../organisation/presentation/pages/mot_de_passe_page.dart';
import '../../../organisation/presentation/pages/organisation_page.dart';
import '../../../organisation/presentation/pages/plateforme_page.dart';
import '../../../organisation/presentation/providers/organisation_providers.dart';
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

  void _ouvrir(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionOrganisationProvider).valueOrNull;
    final active = session?.active;
    final role = active?.role ?? RoleMembre.lecteur;
    final abonnement = ref.watch(organisationCouranteProvider).valueOrNull?.abonnement;
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
          _BandeauProfil(
            nom: session?.profil.nomComplet ?? '',
            detail: active == null ? '' : '${role.libelle} · ${active.organisation}',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsCard(
                  fond: kSettingsHeaderFond,
                  children: [
                    SettingsTile(
                      icon: Icons.business_rounded,
                      title: 'Mon organisation',
                      description: 'Identité du bailleur et logo, imprimés sur les documents',
                      onTap: () => _ouvrir(context, const OrganisationPage()),
                    ),
                    if (role.estAdmin)
                      SettingsTile(
                        icon: Icons.groups_2_outlined,
                        title: 'Équipe',
                        description: abonnement == null
                            ? 'Collaborateurs et rôles'
                            : '${abonnement.membres} utilisateur${abonnement.membres > 1 ? 's' : ''} actif${abonnement.membres > 1 ? 's' : ''}',
                        onTap: () => _ouvrir(context, const EquipePage()),
                      ),
                    SettingsTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Abonnement',
                      description: abonnement == null
                          ? 'Formule et consommation'
                          : '${abonnement.plan.libelle} · ${abonnement.statut.libelle}',
                      onTap: () => _ouvrir(context, const AbonnementPage()),
                    ),
                    if ((session?.profil.organisations.length ?? 0) > 1)
                      SettingsTile(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Changer d\'organisation',
                        description: '${session!.profil.organisations.length} organisations',
                        onTap: () => _ouvrir(context, const ChoixOrganisationPage(depuisReglages: true)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SettingsCard(
                  fond: kSettingsHeaderFond,
                  children: [
                    SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Mot de passe',
                      description: session?.profil.identifiant,
                      onTap: () => _ouvrir(context, const MotDePassePage()),
                    ),
                    SettingsTile(
                      icon: Icons.dialpad_rounded,
                      title: 'Modifier mon code',
                      description: 'Code TMK à ${PinService.codeLength} '
                          'chiffres d\'ouverture de l\'application',
                      // Le code est toujours installé (il conditionne
                      // l'ouverture) : droit au changement, code actuel exigé.
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => PinSetupPage(
                            requireCurrentCode: true,
                            onDone: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                    const _LigneBiometrie(),
                    if (session?.profil.superAdmin ?? false)
                      SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Plateforme',
                        description: 'Organisations clientes et abonnements',
                        onTap: () => _ouvrir(context, const PlateformePage()),
                      ),
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
  final String detail;

  const _BandeauProfil({required this.nom, required this.detail});

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
                Text(detail.isEmpty ? 'Gestion immobilière' : detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Réglage du déverrouillage biométrique, repris de VTC Manager.
///
/// La ligne prend le nom de ce que sait faire l'appareil (Face ID, empreinte
/// digitale…) et n'est actionnable que si une donnée biométrique y est
/// enrôlée ; à défaut, elle reste en retrait avec le motif.
class _LigneBiometrie extends ConsumerStatefulWidget {
  const _LigneBiometrie();

  @override
  ConsumerState<_LigneBiometrie> createState() => _LigneBiometrieState();
}

class _LigneBiometrieState extends ConsumerState<_LigneBiometrie> {
  BiometricAvailability? _dispo;
  bool _active = false;
  bool _occupee = false;

  /// Position visée pendant la bascule : l'interrupteur s'y place aussitôt,
  /// la validation se jouant dans la fenêtre de l'OS.
  bool? _cible;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final auth = ref.read(authNotifierProvider.notifier);
    final dispo = await auth.biometricAvailability();
    final active = await auth.isBiometricsEnabled();
    if (!mounted) return;
    setState(() {
      _dispo = dispo;
      _active = active;
    });
  }

  Future<void> _basculer(bool active) async {
    setState(() {
      _occupee = true;
      _cible = active;
    });
    // L'activation passe par une validation biométrique de l'OS : sans elle,
    // on rangerait la clé du coffre pour quelqu'un qui ne saurait pas s'en
    // servir.
    final auth = ref.read(authNotifierProvider.notifier);
    String? erreur;
    if (active) {
      erreur = await auth.enableBiometrics();
    } else {
      await auth.disableBiometrics();
    }
    if (!mounted) return;
    setState(() {
      _occupee = false;
      _cible = null;
      _active = active && erreur == null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erreur ??
            (active
                ? 'Déverrouillage biométrique activé.'
                : 'Déverrouillage biométrique désactivé.')),
        backgroundColor: erreur == null ? AppColors.primary : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dispo = _dispo;
    final utilisable = (dispo?.disponible ?? false) && !_occupee;

    return SettingsTile(
      icon: dispo?.icone ?? Icons.fingerprint_rounded,
      title: 'Déverrouillage biométrique',
      description: switch (dispo) {
        null => 'Vérification de cet appareil…',
        BiometricAvailability(disponible: true, :final libelleAvecArticle) =>
          'Ouvrir l\'application avec $libelleAvecArticle, sans saisir '
              'le code TMK',
        BiometricAvailability(:final raison?) => raison,
        _ => 'Cet appareil ne dispose pas de capteur biométrique',
      },
      onTap: utilisable ? () => _basculer(!_active) : null,
      trailing: SettingsSwitch(
        value: _cible ?? _active,
        onChanged: utilisable ? _basculer : null,
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
