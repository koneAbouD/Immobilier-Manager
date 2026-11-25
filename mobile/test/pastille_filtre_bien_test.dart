import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/features/immeuble/domain/entities/immeuble.dart';
import 'package:immobilier_manager/features/immeuble/presentation/providers/immeuble_providers.dart';
import 'package:immobilier_manager/features/immeuble/presentation/widgets/pastille_filtre_bien.dart';

void main() {
  const palmiers = Immeuble(id: 1, nom: 'Résidence Les Palmiers', nombreAppartements: 4, nombreOccupes: 3);
  const plateau = Immeuble(id: 2, nom: 'Plateau Center', type: TypeBien.courBasse, ville: 'Abidjan');

  Future<List<Immeuble?>> monter(WidgetTester tester, {Immeuble? bien}) async {
    final choix = <Immeuble?>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [immeublesListeProvider.overrideWith((ref) async => [palmiers, plateau])],
      child: MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PastilleFiltreBien(
              bien: bien,
              onChanged: (b) => setState(() {
                choix.add(b);
                bien = b;
              }),
            ),
          ),
        ),
      ),
    ));
    return choix;
  }

  testWidgets('choisir un bien dans la feuille filtre la liste sur ce bien', (tester) async {
    final choix = await monter(tester);
    expect(find.text('Tous les biens'), findsOneWidget);

    await tester.tap(find.text('Tous les biens'));
    await tester.pumpAndSettle();
    expect(find.text('Filtrer par bien'), findsOneWidget);
    expect(find.text('3/4 occupés'), findsOneWidget);

    await tester.tap(find.text('Plateau Center'));
    await tester.pumpAndSettle();
    expect(choix.single?.id, 2);
    // La pastille affiche le bien choisi.
    expect(find.text('Plateau Center'), findsOneWidget);
  });

  testWidgets('la croix retire le filtre sans rouvrir la feuille', (tester) async {
    final choix = await monter(tester, bien: palmiers);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(choix, [null]);
    expect(find.text('Filtrer par bien'), findsNothing);
    expect(find.text('Tous les biens'), findsOneWidget);
  });

  testWidgets('refermer la feuille sans choisir ne change rien', (tester) async {
    final choix = await monter(tester, bien: palmiers);

    await tester.tap(find.text('Résidence Les Palmiers'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(choix, isEmpty);
  });
}
