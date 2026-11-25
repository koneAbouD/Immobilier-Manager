import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/error/exception.dart';
import 'package:immobilier_manager/core/error/failure.dart';
import 'package:immobilier_manager/core/error/guard.dart';

void main() {
  group('messageErreur', () {
    test('montre tel quel un message déjà lisible', () {
      expect(messageErreur('Ce logement a déjà un bail actif.'),
          'Ce logement a déjà un bail actif.');
      expect(messageErreur(const ConflictFailure('Refusé.')), 'Refusé.');
      expect(messageErreur(const ApiException(409, 'Déjà loué.')), 'Déjà loué.');
      expect(messageErreur(const NetworkException('Pas de réseau.')), 'Pas de réseau.');
      expect(messageErreur(const ErreurLisible('GPS coupé.')), 'GPS coupé.');
    });

    test('ne montre jamais une erreur technique brute', () {
      expect(messageErreur(const FormatException('Unexpected character')),
          kMsgErreurInattendue);
      expect(messageErreur(StateError('Bad state: No element')), kMsgErreurInattendue);
      expect(messageErreur(null), kMsgErreurInattendue);
      expect(messageErreur('   '), kMsgErreurInattendue);
    });

    test('accepte un message de repli propre à l\'écran', () {
      expect(messageErreur(Exception('x'), fallback: 'Chargement impossible.'),
          'Chargement impossible.');
    });
  });

  group('failureFromApi', () {
    test('classe les statuts HTTP en conservant le code métier', () {
      expect(failureFromApi(const ApiException(400, 'm', code: 'VALIDATION_FAILED')),
          isA<ValidationFailure>().having((f) => f.code, 'code', 'VALIDATION_FAILED'));
      expect(failureFromApi(const ApiException(413, 'm')), isA<ValidationFailure>());
      expect(failureFromApi(const ApiException(422, 'm')), isA<ValidationFailure>());
      expect(failureFromApi(const ApiException(403, 'm', code: 'ACCESS_DENIED')),
          isA<AccesRefuseFailure>());
      expect(failureFromApi(const ApiException(409, 'm', code: 'REFERENCE_EXISTANTE')),
          isA<ConflictFailure>().having((f) => f.code, 'code', 'REFERENCE_EXISTANTE'));
      expect(failureFromApi(const ApiException(500, 'm')), isA<ServerFailure>());
    });
  });

  test('guard transforme un bug en échec neutre au lieu de planter', () async {
    final r = await guard<int>(() async => throw TypeError());
    expect(r.getLeft().toNullable(), isA<UnknownFailure>());
  });
}
