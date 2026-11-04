import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/error/exception.dart';
import 'package:immobilier_manager/core/error/failure.dart';
import 'package:immobilier_manager/core/error/guard.dart';

void main() {
  test('un succès devient Right', () async {
    final r = await guard(() async => 42);
    expect(r.getRight().toNullable(), 42);
  });

  test('un 409 devient ConflictFailure avec son code métier', () async {
    final r = await guard<int>(() async => throw const ApiException(
        409, 'Le logement A01 a déjà un bail actif.',
        code: 'APPARTEMENT_DEJA_LOUE'));
    final f = r.getLeft().toNullable();
    expect(f, isA<ConflictFailure>());
    expect((f as ConflictFailure).code, 'APPARTEMENT_DEJA_LOUE');
    expect(f.message, 'Le logement A01 a déjà un bail actif.');
  });

  test('les statuts HTTP sont classés', () async {
    Future<Failure?> echec(int status) async =>
        (await guard<void>(() async => throw ApiException(status, 'x'))).getLeft().toNullable();
    expect(await echec(400), isA<ValidationFailure>());
    expect(await echec(401), isA<AuthFailure>());
    expect(await echec(404), isA<NotFoundFailure>());
    expect(await echec(500), isA<ServerFailure>());
  });

  test('une erreur réseau garde son message', () async {
    final r = await guard<void>(() async => throw const NetworkException('Hors ligne'));
    expect(r.getLeft().toNullable(), isA<NetworkFailure>());
    expect(r.getLeft().toNullable()!.message, 'Hors ligne');
  });
}
