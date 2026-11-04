import 'package:intl/intl.dart';

final _montant = NumberFormat.decimalPattern('fr_FR');
final _date = DateFormat('dd/MM/yyyy', 'fr_FR');
final _mois = DateFormat('MMMM yyyy', 'fr_FR');
final _isoDate = DateFormat('yyyy-MM-dd');
final _isoMois = DateFormat('yyyy-MM');

/// « 150 000 FCFA ».
String formatMontant(num? montant) =>
    montant == null ? '—' : '${_montant.format(montant.round())} FCFA';

/// « 05/10/2026 ».
String formatDate(DateTime? date) => date == null ? '—' : _date.format(date);

/// « Octobre 2026 ».
String formatMois(DateTime? periode) {
  if (periode == null) return '—';
  final s = _mois.format(periode);
  return s[0].toUpperCase() + s.substring(1);
}

/// Format attendu par l'API pour une date (`2026-10-05`).
String isoDate(DateTime date) => _isoDate.format(date);

/// Format attendu par l'API pour un mois (`2026-10`).
String isoMois(DateTime date) => _isoMois.format(date);

DateTime? parseDate(Object? raw) =>
    raw is String && raw.isNotEmpty ? DateTime.tryParse(raw) : null;

double? parseNum(Object? raw) => raw is num ? raw.toDouble() : null;

/// Montant saisi (« 150 000 », « 150000,5 ») → nombre, ou null si vide/invalide.
double? parseMontantSaisi(String? texte) {
  if (texte == null) return null;
  final propre = texte.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(',', '.');
  return propre.isEmpty ? null : double.tryParse(propre);
}
