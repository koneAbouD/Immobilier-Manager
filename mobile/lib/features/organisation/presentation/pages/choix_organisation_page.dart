import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app/redemarrage.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/organisation_providers.dart';
import '../widgets/carte_organisation.dart';

/// Choix de l'organisation de travail. Au démarrage (plusieurs organisations,
/// aucun choix mémorisé) l'écran est imposé ; depuis les réglages il permet de
/// basculer. Basculer redémarre l'application sur un conteneur neuf : aucune
/// donnée de l'organisation quittée ne reste affichée.
class ChoixOrganisationPage extends ConsumerWidget {
  /// Faux au démarrage : pas de retour possible, seulement la déconnexion.
  final bool depuisReglages;

  const ChoixOrganisationPage({super.key, this.depuisReglages = false});

  Future<void> _choisir(WidgetRef ref, int organisationId) async {
    await ref.read(secureStorageProvider).setOrganisationId(organisationId);
    await Redemarrage.lancer();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionOrganisationProvider).valueOrNull;
    final organisations = session?.profil.organisations ?? const [];
    return Scaffold(
      appBar: AppHeader(
        title: 'Mes organisations',
        showBack: depuisReglages,
        action: depuisReglages
            ? null
            : AppHeaderAction(
                icon: Icons.logout_rounded,
                onTap: () => ref.read(authNotifierProvider.notifier).logout(),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            depuisReglages
                ? 'Choisissez l\'organisation dans laquelle travailler.'
                : 'Bonjour ${session?.profil.prenom ?? ''} ! Votre compte donne accès à plusieurs '
                    'organisations : dans laquelle voulez-vous travailler ?',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.label),
          ),
          const SizedBox(height: 16),
          for (final adhesion in organisations)
            CarteOrganisation(
              adhesion: adhesion,
              active: adhesion.organisationId == session?.active?.organisationId,
              onTap: () => adhesion.organisationId == session?.active?.organisationId
                  ? Navigator.of(context).maybePop()
                  : _choisir(ref, adhesion.organisationId),
            ),
        ],
      ),
    );
  }
}
