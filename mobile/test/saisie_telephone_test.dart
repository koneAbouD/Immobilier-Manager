import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/utils/saisie_telephone.dart';

/// Simule une frappe : ancien texte, nouveau texte, curseur en fin de saisie.
TextEditingValue taper(String ancien, String nouveau, {int? curseur}) => const TelephoneFormatter().formatEditUpdate(
      TextEditingValue(text: ancien, selection: TextSelection.collapsed(offset: ancien.length)),
      TextEditingValue(text: nouveau, selection: TextSelection.collapsed(offset: curseur ?? nouveau.length)),
    );

void main() {
  group('formaterTelephone', () {
    test('groupe un numéro ivoirien par deux', () {
      expect(formaterTelephone('0707123456'), '07 07 12 34 56');
      expect(formaterTelephone('07071'), '07 07 1');
    });

    test('coupe au-delà de 10 chiffres', () {
      expect(formaterTelephone('070712345699'), '07 07 12 34 56');
    });

    test('isole l\'indicatif +225 ou 00225', () {
      expect(formaterTelephone('+2250707123456'), '+225 07 07 12 34 56');
      expect(formaterTelephone('002250707123456'), '00225 07 07 12 34 56');
      expect(formaterTelephone('+225'), '+225');
    });

    test('laisse d\'un bloc un numéro étranger', () {
      expect(formaterTelephone('+33612345678'), '+33612345678');
    });
  });

  group('TelephoneFormatter', () {
    test('ajoute les espaces pendant la frappe', () {
      final v = taper('07 07 1', '07 07 12');
      expect(v.text, '07 07 12');
      final w = taper('07 07 12', '07 07 123');
      expect(w.text, '07 07 12 3');
      expect(w.selection.extentOffset, w.text.length);
    });

    test('un retour arrière sur un espace efface le chiffre qui le précède', () {
      // « 07 07 12 3| » → retour arrière sur l'espace avant le 3 a déjà été
      // fait ici : on efface l'espace entre 12 et 3, curseur après « 12 ».
      final v = taper('07 07 12 3', '07 07 123', curseur: 8);
      expect(v.text, '07 07 13');
      expect(v.selection.extentOffset, 7);
    });

    test('garde le curseur à sa place pour une insertion au milieu', () {
      // Insertion de « 9 » après « 07 0 ».
      final v = taper('07 07 12', '07 097 12', curseur: 5);
      expect(v.text, '07 09 71 2');
      // Juste derrière le « 9 » inséré.
      expect(v.selection.extentOffset, 5);
    });

    test('ne touche pas à une adresse e-mail', () {
      final v = taper('demo@tmk.c', 'demo@tmk.ci');
      expect(v.text, 'demo@tmk.ci');
    });

    test('un collage est mis en forme', () {
      expect(taper('', '+225 0707123456').text, '+225 07 07 12 34 56');
    });
  });

  group('valeurs envoyées et vérification', () {
    test('telephoneSaisi retire les espaces', () {
      expect(telephoneSaisi('07 07 12 34 56'), '0707123456');
      expect(telephoneSaisi('+225 07 07 12 34 56'), '+2250707123456');
      expect(telephoneSaisi('   '), isNull);
    });

    test('saisieTelephone met en forme la valeur enregistrée', () {
      expect(saisieTelephone('0707010203'), '07 07 01 02 03');
      expect(saisieTelephone(null), '');
    });

    test('verifierTelephone exige 10 chiffres pour un numéro ivoirien', () {
      expect(verifierTelephone('07 07 12 34 56'), isNull);
      expect(verifierTelephone('+225 07 07 12 34 56'), isNull);
      expect(verifierTelephone('07 07 12'), contains('10 chiffres'));
      expect(verifierTelephone('', obligatoire: true), 'Téléphone obligatoire.');
      expect(verifierTelephone(''), isNull);
      expect(verifierTelephone('+33612345678'), isNull);
    });
  });
}
