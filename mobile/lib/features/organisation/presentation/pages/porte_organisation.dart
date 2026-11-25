import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_ui.dart';
import '../../domain/entities/organisation.dart';
import '../providers/organisation_providers.dart';
import 'choix_organisation_page.dart';

/// Passage obligé entre la connexion et l'application : charge le profil,
/// fixe l'organisation de travail (ou la fait choisir) et arrête l'accès si
/// l'abonnement de l'organisation est résilié.
class PorteOrganisation extends ConsumerWidget {
  final Widget child;

  const PorteOrganisation({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionOrganisationProvider);
    return session.when(
      loading: () => const _Attente(),
      error: (e, _) => _Impasse(
        icone: Icons.cloud_off_rounded,
        titre: 'Connexion impossible',
        message: messageErreur(e),
        action: 'Réessayer',
        onAction: () => ref.invalidate(sessionOrganisationProvider),
      ),
      data: (s) {
        if (s.profil.organisations.isEmpty) {
          return const _Impasse(
            icone: Icons.domain_disabled_rounded,
            titre: 'Aucune organisation',
            message: 'Votre compte n\'est rattaché à aucune organisation active. Demandez à '
                'l\'administrateur de votre agence de vous inviter, ou créez un nouveau compte.',
          );
        }
        final active = s.active;
        if (active == null) return const ChoixOrganisationPage();
        if (active.acces == AccesOrganisation.bloque) {
          return _Impasse(
            icone: Icons.block_rounded,
            titre: 'Accès suspendu',
            message: 'L\'abonnement de « ${active.organisation} » est résilié. '
                'Contactez l\'éditeur pour le réactiver.',
            action: s.profil.organisations.length > 1 ? 'Changer d\'organisation' : null,
            onAction: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const ChoixOrganisationPage(depuisReglages: true))),
          );
        }
        return child;
      },
    );
  }
}

class _Attente extends StatelessWidget {
  const _Attente();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AuthBrand(assetLogo: 'assets/images/logo_tmk.png', compact: true, subtitle: ''),
            SizedBox(height: 28),
            CircularProgressIndicator(),
          ]),
        ),
      );
}

/// Écran sans issue dans l'application : explication, action éventuelle et
/// déconnexion.
class _Impasse extends ConsumerWidget {
  final IconData icone;
  final String titre;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  const _Impasse({required this.icone, required this.titre, required this.message, this.action, this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                    child: Icon(icone, size: 34, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 20),
                  Text(titre,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 10),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.label)),
                  const SizedBox(height: 28),
                  if (action != null) ...[
                    BoutonPrincipal(label: action!, onPressed: onAction),
                    const SizedBox(height: 10),
                  ],
                  BoutonSecondaire(
                    label: 'Se déconnecter',
                    icon: Icons.logout_rounded,
                    onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
