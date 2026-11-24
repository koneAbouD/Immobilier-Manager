import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/features/auth/presentation/pages/inscription_page.dart';

/// La page d'inscription doit tenir sur un écran sans défiler, du petit
/// téléphone à la tablette (le défilement ne sert qu'en secours, clavier ouvert).
void main() {
  const ecrans = <String, Size>{
    'iPhone SE (375×667)': Size(375, 667),
    'Android courant (360×740)': Size(360, 740),
    'Galaxy Fold fermé (344×882)': Size(344, 882),
    'Galaxy Fold ouvert (884×1104)': Size(884, 1104),
    'tablette paysage (1280×800)': Size(1280, 800),
  };

  for (final MapEntry(key: nom, value: taille) in ecrans.entries) {
    testWidgets('tient sans défiler : $nom', (tester) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: InscriptionPage())));
      await tester.pumpAndSettle();

      final defilement = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      expect(defilement.maxScrollExtent, 0, reason: 'la page défile de ${defilement.maxScrollExtent}px');
      expect(tester.takeException(), isNull);
      // Le dernier élément, « Déjà un compte ? », est à l'écran.
      final lien = tester.getRect(find.textContaining('Déjà un compte', findRichText: true));
      expect(lien.bottom, lessThanOrEqualTo(taille.height));
    });
  }

  testWidgets('les erreurs de saisie restent visibles sans défiler', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: InscriptionPage())));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Téléphone obligatoire.'), findsOneWidget);
    final defilement = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(defilement.maxScrollExtent, 0, reason: 'la page défile de ${defilement.maxScrollExtent}px');
  });
}
