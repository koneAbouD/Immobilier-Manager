import 'package:flutter/material.dart';

import '../core/widgets/app_header.dart';

/// Page d'une section ouverte depuis l'accueil (Biens, Locataires, Loyers,
/// Travaux) : en-tête titré avec retour, puis le contenu de la section.
class SectionPage extends StatelessWidget {
  final String titre;
  final Widget child;

  const SectionPage({super.key, required this.titre, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: titre),
      body: SafeArea(top: false, child: child),
    );
  }
}
