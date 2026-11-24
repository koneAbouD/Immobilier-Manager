import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_header.dart';
import '../features/organisation/presentation/providers/organisation_providers.dart';
import '../features/organisation/presentation/widgets/bandeau_abonnement.dart';
import '../features/parametrage/presentation/pages/settings_screen.dart';
import '../features/tableau_bord/presentation/pages/tableau_bord_page.dart';

/// Coquille de l'application : l'accueil, sans barre de navigation. Les
/// sections (Biens, Locataires, Loyers, Travaux) s'ouvrent en pages depuis
/// les boutons de l'accueil.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: '',
        showBack: false,
        // Menu, qui ouvre les réglages (organisation, équipe, apparence…).
        leading: AppHeaderAction(
          icon: Icons.menu_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        center: const _Salutation(),
      ),
      body: const SafeArea(
        top: false,
        child: Column(children: [
          BandeauAbonnement(),
          Expanded(child: TableauBordPage()),
        ]),
      ),
    );
  }
}

/// Nom de l'organisation active au centre de l'en-tête : on sait toujours
/// dans quel espace on travaille.
class _Salutation extends ConsumerWidget {
  const _Salutation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organisation = ref.watch(sessionOrganisationProvider).valueOrNull?.active?.organisation;
    return Text(
      organisation ?? 'Immobilier Manager',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.dark,
        letterSpacing: -0.3,
      ),
    );
  }
}
