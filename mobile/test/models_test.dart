import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/features/appartement/data/models/appartement_model.dart';
import 'package:immobilier_manager/features/appartement/domain/entities/appartement.dart';
import 'package:immobilier_manager/features/loyer/data/models/loyer_models.dart';
import 'package:immobilier_manager/features/loyer/domain/entities/echeance.dart';

void main() {
  test('EcheanceModel lit la réponse du backend', () {
    final e = EcheanceModel.fromJson({
      'id': 3,
      'bailId': 1,
      'bailReference': 'BAIL-00001',
      'locataireId': 2,
      'locataireNom': 'Aya Kouassi',
      'appartementReference': 'A01',
      'immeubleNom': 'Résidence Les Palmiers',
      'periode': '2026-08-01',
      'dateEcheance': '2026-08-05',
      'montantDu': 160000.00,
      'montantPaye': 100000,
      'resteDu': 60000.0,
      'statut': 'PARTIEL',
      'enRetard': true,
    });
    expect(e.statut, StatutEcheance.partiel);
    expect(e.encaissable, isTrue);
    expect(e.resteDu, 60000);
    expect(e.periode, DateTime(2026, 8, 1));
    expect(e.logement, 'A01 — Résidence Les Palmiers');
  });

  test('AppartementModel fait l\'aller-retour des codes d\'énumération', () {
    final a = AppartementModel.fromJson({
      'id': 1,
      'immeubleId': 1,
      'reference': 'B11',
      'etage': 1,
      'type': 'CHAMBRE_SALON',
      'loyerMensuel': 90000,
      'charges': 5000,
      'statut': 'EN_TRAVAUX',
    });
    expect(a.type, TypeLogement.chambreSalon);
    expect(a.statut, StatutAppartement.enTravaux);
    expect(a.montantMensuel, 95000);
    expect(a.libelleEtage, '1er étage');
    final json = AppartementModel.toJson(a);
    expect(json['type'], 'CHAMBRE_SALON');
    expect(json['statut'], 'EN_TRAVAUX');
  });
}
