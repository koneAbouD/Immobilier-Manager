import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/bail.dart';

abstract interface class BailRepository {
  Future<Either<Failure, PageResult<Bail>>> getPage({
    int page,
    int size,
    int? appartementId,
    int? locataireId,
    StatutBail? statut,
    String? recherche,
  });

  Future<Either<Failure, Bail>> getById(int id);

  Future<Either<Failure, Bail>> create(Bail bail);

  Future<Either<Failure, Bail>> update(int id, Bail bail);

  Future<Either<Failure, Bail>> resilier(int id, {DateTime? date, required String motif});

  Future<Either<Failure, Uint8List>> genererContrat(int id);

  Future<Either<Failure, Bail>> deposerContratSigne(int id,
      {required Uint8List contenu, required String nomFichier, required String type});

  Future<Either<Failure, Uint8List>> telechargerContratSigne(int id);
}
