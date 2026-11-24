import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/organisation.dart';
import '../pages/abonnement_page.dart';
import '../providers/organisation_providers.dart';

/// Rappel discret en tête de l'accueil : fin d'essai proche, ou abonnement qui
/// ne laisse plus que la consultation. Invisible le reste du temps.
class BandeauAbonnement extends ConsumerWidget {
  const BandeauAbonnement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organisation = ref.watch(organisationCouranteProvider).valueOrNull;
    if (organisation == null) return const SizedBox.shrink();
    final a = organisation.abonnement;

    final (String message, Color couleur, IconData icone) = switch (a) {
      Abonnement(acces: AccesOrganisation.lectureSeule) => (
          a.motifRestriction ?? 'Consultation seule : l\'abonnement ne permet plus de modifications.',
          AppColors.warning,
          Icons.lock_clock_outlined,
        ),
      Abonnement(statut: StatutAbonnement.essai) when a.echeanceProche => (
          a.joursRestants == 0
              ? 'Dernier jour d\'essai gratuit : choisissez une formule pour continuer.'
              : 'Essai gratuit : ${a.joursRestants} jour${a.joursRestants! > 1 ? 's' : ''} restant${a.joursRestants! > 1 ? 's' : ''}.',
          AppColors.info,
          Icons.hourglass_bottom_rounded,
        ),
      Abonnement(statut: StatutAbonnement.actif) when a.echeanceProche => (
          'Votre abonnement arrive à échéance dans ${a.joursRestants} jour(s).',
          AppColors.info,
          Icons.event_repeat_rounded,
        ),
      _ => ('', AppColors.info, Icons.info_outline),
    };
    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const AbonnementPage())),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(icone, size: 20, color: couleur),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: AppColors.dark)),
              ),
              Icon(Icons.chevron_right_rounded, color: couleur),
            ]),
          ),
        ),
      ),
    );
  }
}
