import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:immobilier_manager/core/error/failure.dart';
import 'package:immobilier_manager/core/network/page_result.dart';
import 'package:immobilier_manager/features/journal/domain/entities/entree_journal.dart';
import 'package:immobilier_manager/features/journal/domain/repositories/journal_repository.dart';
import 'package:immobilier_manager/features/journal/presentation/pages/journal_actions_page.dart';
import 'package:immobilier_manager/features/journal/presentation/providers/journal_providers.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FauxJournal implements JournalRepository {
  final List<EntreeJournal> entrees;
  final demandes = <(TypeEntiteJournal?, ActionJournal?)>[];

  _FauxJournal(this.entrees);

  @override
  Future<Either<Failure, PageResult<EntreeJournal>>> getPage({
    int page = 0,
    int size = 20,
    TypeEntiteJournal? type,
    ActionJournal? action,
    String? recherche,
  }) async {
    demandes.add((type, action));
    final filtrees = entrees
        .where((e) => (type == null || e.type == type) && (action == null || e.action == action))
        .toList();
    return Right(PageResult(
        content: filtrees, page: 0, size: size, totalElements: filtrees.length, totalPages: 1, last: true));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  final maintenant = DateTime.now();
  final hier = maintenant.subtract(const Duration(days: 1));
  final entrees = [
    EntreeJournal.fromJson({
      'id': 2,
      'date': maintenant.toIso8601String(),
      'action': 'MODIFICATION',
      'typeEntite': 'LOCAL',
      'entiteId': 7,
      'libelle': 'A3',
      'contexte': 'Résidence Palmiers',
      'auteurNom': 'Awa Koné',
      'changements': [
        {'champ': 'Loyer mensuel', 'avant': '150 000 FCFA', 'apres': '175 000 FCFA'},
        {'champ': 'Description', 'avant': null, 'apres': 'Vue mer'},
      ],
    }),
    EntreeJournal.fromJson({
      'id': 1,
      'date': hier.toIso8601String(),
      'action': 'SUPPRESSION',
      'typeEntite': 'LOCATAIRE',
      'entiteId': 4,
      'libelle': 'Jean Kouassi',
      'auteurNom': 'Awa Koné',
      'changements': [
        {'champ': 'Téléphone', 'avant': '0707123456', 'apres': null},
      ],
    }),
  ];

  Future<_FauxJournal> afficher(WidgetTester tester) async {
    final repo = _FauxJournal(entrees);
    await tester.pumpWidget(ProviderScope(
      overrides: [journalRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: JournalActionsPage()),
    ));
    await tester.pumpAndSettle();
    return repo;
  }

  test('les jours se nomment simplement', () {
    final ref = DateTime(2026, 11, 25, 10);
    expect(libelleJour(DateTime(2026, 11, 25, 8), maintenant: ref), 'Aujourd\'hui');
    expect(libelleJour(DateTime(2026, 11, 24, 23), maintenant: ref), 'Hier');
    expect(libelleJour(DateTime(2026, 11, 18), maintenant: ref), 'Mercredi 18 novembre');
    expect(libelleJour(DateTime(2025, 11, 18), maintenant: ref), 'Mardi 18 novembre 2025');
  });

  testWidgets('entrées groupées par jour, avec action et aperçu du changement', (tester) async {
    await afficher(tester);

    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Modifié'), findsOneWidget);
    expect(find.text('Supprimé'), findsOneWidget);
    expect(find.text('Local · Résidence Palmiers'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('le détail montre chaque champ avant → après', (tester) async {
    await afficher(tester);

    await tester.tap(find.text('A3'));
    await tester.pumpAndSettle();

    expect(find.text('2 champs modifiés'.toUpperCase()), findsOneWidget);
    expect(find.text('150 000 FCFA'), findsOneWidget);
    expect(find.text('175 000 FCFA'), findsOneWidget);
    expect(find.text('Non renseigné'), findsOneWidget);
    expect(find.text('Ouvrir la fiche du local'), findsOneWidget);
  });

  testWidgets('une suppression montre les dernières valeurs, sans lien vers la fiche', (tester) async {
    await afficher(tester);

    await tester.tap(find.text('Jean Kouassi'));
    await tester.pumpAndSettle();

    expect(find.text('Valeurs au moment de la suppression'.toUpperCase()), findsOneWidget);
    expect(find.text('0707123456'), findsOneWidget);
    expect(find.textContaining('Ouvrir la fiche'), findsNothing);
  });

  testWidgets('les filtres type et action interrogent le serveur', (tester) async {
    final repo = await afficher(tester);

    await tester.tap(find.text('Locataires'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suppressions'));
    await tester.pumpAndSettle();

    expect(repo.demandes.last, (TypeEntiteJournal.locataire, ActionJournal.suppression));
    expect(find.text('Jean Kouassi'), findsOneWidget);
    expect(find.text('A3'), findsNothing);
  });
}
