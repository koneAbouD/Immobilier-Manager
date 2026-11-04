import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/utils/formatters.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  test('montant en FCFA avec séparateur de milliers', () {
    expect(formatMontant(150000).replaceAll(' ', ' ').replaceAll(' ', ' '), '150 000 FCFA');
    expect(formatMontant(null), '—');
  });

  test('mois avec majuscule initiale', () {
    expect(formatMois(DateTime(2026, 10, 1)), 'Octobre 2026');
  });

  test('formats API', () {
    expect(isoDate(DateTime(2026, 3, 5)), '2026-03-05');
    expect(isoMois(DateTime(2026, 3, 5)), '2026-03');
  });

  test('saisie de montant tolérante aux espaces et virgules', () {
    expect(parseMontantSaisi('150 000'), 150000);
    expect(parseMontantSaisi('1500,5'), 1500.5);
    expect(parseMontantSaisi(''), isNull);
    expect(parseMontantSaisi('abc'), isNull);
  });
}
