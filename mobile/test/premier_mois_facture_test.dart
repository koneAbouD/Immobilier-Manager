import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/features/bail/domain/entities/bail.dart';

void main() {
  final creation = DateTime(2026, 11, 24);

  test('sans avance : le mois qui suit l\'enregistrement', () {
    expect(Bail.calculerPremierMoisFacture(DateTime(2026, 11, 15), 0, creation), DateTime(2026, 12));
  });

  test('les mois d\'avance repoussent le premier loyer', () {
    expect(Bail.calculerPremierMoisFacture(DateTime(2026, 12, 1), 2, creation), DateTime(2027, 2));
    expect(Bail.calculerPremierMoisFacture(DateTime(2027, 3, 1), 1, creation), DateTime(2027, 4));
  });

  test('un bail ancien n\'est pas facturé rétroactivement', () {
    expect(Bail.calculerPremierMoisFacture(DateTime(2024, 1, 1), 2, creation), DateTime(2026, 12));
  });

  test('passage d\'année', () {
    expect(Bail.calculerPremierMoisFacture(DateTime(2026, 11, 1), 3, creation), DateTime(2027, 2));
  });
}
