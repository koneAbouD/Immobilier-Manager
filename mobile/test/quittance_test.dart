import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/utils/formatters.dart';
import 'package:immobilier_manager/core/utils/telephone.dart';
import 'package:immobilier_manager/core/utils/whatsapp.dart';
import 'package:immobilier_manager/features/loyer/domain/entities/echeance.dart';
import 'package:immobilier_manager/features/loyer/domain/entities/paiement.dart';
import 'package:immobilier_manager/features/loyer/presentation/widgets/quittance.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Echeance echeance({double paye = 50000, double reste = 45000}) => Echeance(
        id: 1,
        bailId: 2,
        locataireId: 3,
        locataireNom: 'Fatou Bamba',
        locataireTelephone: '01 01 07 08 09',
        appartementReference: 'B11',
        immeubleNom: 'Résidence Les Palmiers',
        periode: DateTime(2026, 11),
        dateEcheance: DateTime(2026, 11, 5),
        montantDu: 95000,
        montantPaye: paye,
        resteDu: reste,
        statut: reste > 0 ? StatutEcheance.partiel : StatutEcheance.payee,
        enRetard: false,
      );

  const paiement = Paiement(
    id: 42,
    montant: 50000,
    modePaiement: ModePaiement.mobileMoney,
    reference: 'OM-123',
  );

  test('le numéro local reçoit l\'indicatif ivoirien, l\'international est gardé', () {
    expect(telephoneInternational('01 01 07 08 09'), '2250101070809');
    expect(telephoneInternational('+225 07 07 01 02 03'), '2250707010203');
    expect(telephoneInternational('00225 0707010203'), '2250707010203');
    expect(telephoneInternational('123'), isNull);
    expect(telephoneInternational(null), isNull);
  });

  test('le lien WhatsApp vise le locataire et garde les espaces du message', () {
    final lien = lienWhatsApp(telephone: '0101070809', message: 'Bonjour Fatou');
    expect(lien.toString(), 'https://wa.me/2250101070809?text=Bonjour%20Fatou');
  });

  test('la quittance salue le locataire, donne le montant, le loyer et le reste dû', () {
    final message = composerQuittance(echeance(), paiement);
    expect(message, contains('Bonjour Fatou,'));
    // Montants au format français (espace fine insécable entre les milliers).
    expect(message, contains('*${formatMontant(50000)}*'));
    expect(message, contains('par Mobile Money'));
    expect(message, contains('Loyer de novembre 2026 — B11 — Résidence Les Palmiers'));
    expect(message, contains('Reste à payer sur ce loyer : *${formatMontant(45000)}*'));
    expect(message, contains('Réf. OM-123'));
  });

  test('un loyer soldé est annoncé comme réglé', () {
    final message = composerQuittance(echeance(paye: 95000, reste: 0), paiement);
    expect(message, contains('Votre loyer de novembre 2026 est réglé.'));
    expect(message, isNot(contains('Reste à payer')));
  });

  test('le nom du fichier est lisible et sans accent', () {
    expect(nomFichierQuittance(echeance()), 'Quittance_fatou_bamba_novembre-2026.pdf');
  });
}
