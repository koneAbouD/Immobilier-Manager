import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/verrou_biometrique.dart';
import '../widgets/auth_ui.dart';

/// Écran de verrou biométrique, au lancement comme au retour au premier plan.
///
/// L'invite système est lancée d'emblée — c'est le geste attendu. Annulée,
/// elle se relance depuis le bouton ; la connexion par mot de passe reste
/// toujours proposée en repli.
///
/// Posé au-dessus du navigateur au retour au premier plan : rien ici ne
/// s'appuie donc sur un `Navigator` ni sur un `Overlay` (pas d'infobulle).
class VerrouBiometriquePage extends ConsumerStatefulWidget {
  const VerrouBiometriquePage({super.key});

  @override
  ConsumerState<VerrouBiometriquePage> createState() =>
      _VerrouBiometriquePageState();
}

class _VerrouBiometriquePageState extends ConsumerState<VerrouBiometriquePage> {
  BiometricAvailability? _dispo;
  bool _enCours = false;
  String? _message;

  /// La biométrie ne peut plus servir : seul reste le mot de passe.
  bool _optionPerdue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preparer());
  }

  Future<void> _preparer() async {
    final verrou = ref.read(verrouBiometriqueProvider.notifier);
    final dispo = await verrou.disponibilite();
    if (!mounted) return;
    setState(() => _dispo = dispo);
    await _deverrouiller();
  }

  Future<void> _deverrouiller() async {
    if (_enCours || _optionPerdue) return;
    setState(() {
      _enCours = true;
      _message = null;
    });
    final issue =
        await ref.read(verrouBiometriqueProvider.notifier).deverrouiller();
    if (!mounted) return;
    setState(() {
      _enCours = false;
      if (issue case DeverrouillageRefuse(:final message, :final optionPerdue)) {
        _message = message;
        _optionPerdue = optionPerdue;
      }
    });
  }

  Future<void> _motDePasse() =>
      ref.read(authNotifierProvider.notifier).seReconnecterParMotDePasse();

  @override
  Widget build(BuildContext context) {
    final dispo = _dispo;
    final libelle = dispo?.libelleAvecArticle ?? 'la biométrie';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthBrand(
                    assetLogo: 'assets/images/logo_tmk.png',
                    compact: true,
                    subtitle: '',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Application verrouillée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _optionPerdue
                        ? 'Reconnectez-vous pour continuer.'
                        : 'Utilisez $libelle pour continuer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.label),
                  ),
                  const SizedBox(height: 32),
                  if (!_optionPerdue)
                    _BoutonBiometrie(
                      icone: dispo?.icone ?? Icons.fingerprint_rounded,
                      libelle: 'Déverrouiller avec $libelle',
                      enCours: _enCours,
                      onTap: _deverrouiller,
                    ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _message!,
                      key: const ValueKey('verrou-message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  TextButton.icon(
                    onPressed: _enCours ? null : _motDePasse,
                    icon: const Icon(Icons.password_rounded, size: 18),
                    label: const Text('Se connecter avec mon mot de passe'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grande touche ronde portant l'icône de la modalité (visage, empreinte).
class _BoutonBiometrie extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final bool enCours;
  final VoidCallback onTap;

  const _BoutonBiometrie({
    required this.icone,
    required this.libelle,
    required this.enCours,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Icône et libellé forment une seule touche : viser l'un ou l'autre
    // relance l'invite.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enCours ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                libelle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
