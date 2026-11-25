import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/features/appartement/domain/entities/appartement.dart';
import 'package:immobilier_manager/features/bail/data/models/bail_model.dart';
import 'package:immobilier_manager/features/bail/domain/entities/bail.dart';

void main() {
  test('le type de bail proposé suit la nature du local', () {
    expect(UsageBail.parDefautPour(TypeLogement.appartement), UsageBail.habitation);
    expect(UsageBail.parDefautPour(TypeLogement.magasin), UsageBail.professionnel);
    expect(UsageBail.parDefautPour(TypeLogement.bureau), UsageBail.professionnel);
  });

  test('le type de bail est envoyé et relu', () {
    final json = BailModel.toJson(
        Bail(appartementId: 1, locataireId: 2, dateDebut: DateTime(2026, 12), usage: UsageBail.professionnel));
    expect(json['usage'], 'PROFESSIONNEL');

    final relu = BailModel.fromJson({'appartementId': 1, 'locataireId': 2, 'dateDebut': '2026-12-01', 'usage': 'HABITATION'});
    expect(relu.usage, UsageBail.habitation);
  });

  test('sans type choisi, rien n\'est envoyé : le serveur garde ou déduit le sien', () {
    final json = BailModel.toJson(Bail(appartementId: 1, locataireId: 2, dateDebut: DateTime(2026, 12)));
    expect(json.containsKey('usage'), isFalse);
  });
}
