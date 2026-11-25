import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/utils/formatters.dart';
import 'package:immobilier_manager/core/utils/separateur_milliers.dart';

const _s = kSeparateurMilliers;
const _f = SeparateurMilliersFormatter();

TextEditingValue _v(String texte, [int? curseur]) => TextEditingValue(
    text: texte, selection: TextSelection.collapsed(offset: curseur ?? texte.length));

void main() {
  test('regroupe les chiffres par milliers', () {
    expect(grouperMilliers('1500000'), '1${_s}500${_s}000');
    expect(grouperMilliers('150'), '150');
    expect(saisieMontant(150000.4), '150${_s}000');
    expect(saisieMontant(null), '');
  });

  test('frappe en fin de champ : séparateurs ajoutés, curseur au bout', () {
    final r = _f.formatEditUpdate(_v('150 00'), _v('1500000'));
    expect(r.text, '1${_s}500${_s}000');
    expect(r.selection.baseOffset, r.text.length);
  });

  test('frappe au milieu : le curseur reste après le chiffre tapé', () {
    // « 1 500| » → on tape 9 après le 5 : « 1 5900 ».
    final ancien = _v('1${_s}500', 3);
    final r = _f.formatEditUpdate(ancien, _v('1${_s}5900', 4));
    expect(r.text, '15${_s}900');
    expect(r.selection.baseOffset, 4);
  });

  test('retour arrière sur un séparateur efface le chiffre précédent', () {
    final ancien = _v('1${_s}500', 2);
    final r = _f.formatEditUpdate(ancien, _v('1500', 1));
    expect(r.text, '500');
    expect(r.selection.baseOffset, 0);
  });

  test('ignore les caractères non numériques et les zéros en tête', () {
    expect(_f.formatEditUpdate(_v(''), _v('00a12')).text, '12');
    expect(_f.formatEditUpdate(_v(''), _v('0')).text, '0');
  });

  test('le texte formaté se relit comme un nombre', () {
    expect(parseMontantSaisi(saisieMontant(1500000)), 1500000);
  });
}
