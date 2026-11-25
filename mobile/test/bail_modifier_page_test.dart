import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:immobilier_manager/core/error/failure.dart';
import 'package:immobilier_manager/features/bail/domain/entities/bail.dart';
import 'package:immobilier_manager/features/bail/domain/repositories/bail_repository.dart';
import 'package:immobilier_manager/features/bail/presentation/pages/bail_modifier_page.dart';
import 'package:immobilier_manager/features/bail/presentation/providers/bail_providers.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Ne connaît que la mise à jour : elle mémorise ce qui est envoyé.
class _FauxBailRepository implements BailRepository {
  Bail? envoye;

  @override
  Future<Either<Failure, Bail>> update(int id, Bail bail) async {
    envoye = bail;
    return Right(bail);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  final bail = Bail(
    id: 9,
    reference: 'BAIL-00009',
    appartementId: 1,
    locataireId: 2,
    locataireNom: 'Awa Koné',
    appartementReference: 'A1',
    dateDebut: DateTime(2026, 12, 1),
    loyerMensuel: 100000,
    charges: 5000,
    depotGarantie: 200000,
    moisCaution: 2,
    moisAvance: 0,
    jourEcheance: 5,
    premierMoisFacture: DateTime(2026, 12, 1),
    creeLe: DateTime(2026, 11, 24),
  );

  Future<_FauxBailRepository> ouvrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FauxBailRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [bailRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: BailModifierPage(bail: bail)),
    ));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('les conditions actuelles sont préremplies', (tester) async {
    await ouvrir(tester);
    expect(find.text('100\u00A0000'), findsOneWidget);
    expect(find.text('Décembre 2026'), findsWidgets);
  });

  testWidgets('l\'avance repousse le premier loyer et la caution n\'est pas renvoyée', (tester) async {
    final repo = await ouvrir(tester);
    final avance = find.widgetWithText(TextFormField, '0').last;
    await tester.enterText(avance, '2');
    await tester.pumpAndSettle();
    expect(find.text('Février 2027'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Enregistrer'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(repo.envoye, isNotNull);
    expect(repo.envoye!.moisAvance, 2);
    // Type de bail inchangé : il n'est pas renvoyé.
    expect(repo.envoye!.usage, isNull);
    // Ni choix manuel (le serveur recalcule), ni caution inchangée renvoyée.
    expect(repo.envoye!.premierMoisFacture, isNull);
    expect(repo.envoye!.moisCaution, isNull);
  });
}
