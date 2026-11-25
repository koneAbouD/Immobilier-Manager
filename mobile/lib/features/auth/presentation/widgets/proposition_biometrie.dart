import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/verrou_biometrique.dart';
import 'auth_ui.dart';

/// Propose une fois d'activer le déverrouillage biométrique, à l'arrivée sur
/// l'accueil juste après une connexion par mot de passe — repris de VTC
/// Manager (`BiometricProposal`).
///
/// La page de connexion disparaît à l'instant où la session s'ouvre (et le
/// conteneur Riverpod est recréé) : l'invite s'accroche donc à l'écran qui lui
/// succède, que ce widget se contente d'envelopper.
///
/// Une seule proposition par compte et par appareil, refus compris : l'option
/// reste ensuite dans les Réglages.
class PropositionBiometrie extends ConsumerStatefulWidget {
  final Widget child;

  const PropositionBiometrie({super.key, required this.child});

  @override
  ConsumerState<PropositionBiometrie> createState() =>
      _PropositionBiometrieState();
}

class _PropositionBiometrieState extends ConsumerState<PropositionBiometrie> {
  @override
  void initState() {
    super.initState();
    // Après le premier rendu : l'accueil est à l'écran, la boîte se pose
    // dessus au lieu d'en retarder l'affichage.
    WidgetsBinding.instance.addPostFrameCallback((_) => _proposer());
  }

  Future<void> _proposer() async {
    final verrou = ref.read(verrouBiometriqueProvider.notifier);
    final dispo = await verrou.aProposer();
    if (!mounted || dispo == null) return;

    // Posée avant la réponse : ni un refus ni une interruption ne doivent
    // faire revenir la question à la prochaine connexion.
    await verrou.marquerProposee();
    if (!mounted) return;

    final accepte = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogueProposition(dispo: dispo),
    );
    if (!mounted || !(accepte ?? false)) return;

    final erreur = await verrou.activer();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erreur ?? 'Déverrouillage biométrique activé.'),
        backgroundColor: erreur == null ? AppColors.primary : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DialogueProposition extends StatelessWidget {
  final BiometricAvailability dispo;

  const _DialogueProposition({required this.dispo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Marges réduites et contenu défilant : la boîte tient sur un téléphone
      // de 360 dp, en paysage comme en grand texte.
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      scrollable: true,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(dispo.icone, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Utiliser ${dispo.libelleAvecArticle} ?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: AppColors.dark),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(
          'Vous rouvrirez l\'application d\'un geste, sans ressaisir votre '
          'mot de passe. Il reste toujours possible de vous reconnecter avec '
          'votre téléphone et votre mot de passe. Vous pourrez changer ce '
          'choix dans les Réglages.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.label, height: 1.4),
        ),
      ),
      // Boutons empilés en pleine largeur : rien ne déborde, quelle que soit
      // la taille de l'écran.
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthPrimaryButton(
              label: 'ACTIVER',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'PLUS TARD',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
