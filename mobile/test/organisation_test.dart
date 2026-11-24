import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/error/exception.dart';
import 'package:immobilier_manager/core/error/failure.dart';
import 'package:immobilier_manager/core/error/guard.dart';
import 'package:immobilier_manager/features/organisation/data/datasources/organisation_remote_datasource.dart';
import 'package:immobilier_manager/features/organisation/domain/entities/organisation.dart';

void main() {
  test('les rôles s\'emboîtent', () {
    expect(RoleMembre.proprietaire.inclut(RoleMembre.lecteur), isTrue);
    expect(RoleMembre.admin.estAdmin, isTrue);
    expect(RoleMembre.gestionnaire.estAdmin, isFalse);
    expect(RoleMembre.gestionnaire.peutEcrire, isTrue);
    expect(RoleMembre.lecteur.peutEcrire, isFalse);
    expect(RoleMembre.fromCode('INCONNU'), RoleMembre.lecteur);
  });

  test('un 402 devient AbonnementFailure avec son code', () async {
    final r = await guard<void>(() async => throw const ApiException(402, 'Limite atteinte', code: 'LIMITE_LOTS_ATTEINTE'));
    final f = r.getLeft().toNullable();
    expect(f, isA<AbonnementFailure>());
    expect((f as AbonnementFailure).code, 'LIMITE_LOTS_ATTEINTE');
  });

  test('l\'organisation courante se lit depuis la réponse du backend', () {
    final o = OrganisationRemoteDatasource.organisation({
      'id': 3,
      'nom': 'Agence Horizon',
      'pays': 'CI',
      'devise': 'XOF',
      'logo': true,
      'monRole': 'ADMIN',
      'abonnement': {
        'plan': {'code': 'ESSENTIEL', 'libelle': 'Essentiel', 'lotsMax': 50, 'membresMax': 3, 'tarifMensuel': 15000},
        'statut': 'ESSAI',
        'acces': 'COMPLET',
        'essaiFinLe': '2026-12-23',
        'joursRestants': 5,
        'biens': 2,
        'lots': 12,
        'membres': 2,
      },
    });
    expect(o.monRole, RoleMembre.admin);
    expect(o.abonnement.statut, StatutAbonnement.essai);
    expect(o.abonnement.plan.lotsMax, 50);
    expect(o.abonnement.echeanceProche, isTrue);
    expect(o.abonnement.essaiFinLe, DateTime(2026, 12, 23));
  });
}
