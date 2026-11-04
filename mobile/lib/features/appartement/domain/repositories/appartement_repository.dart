import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/appartement.dart';

abstract interface class AppartementRepository {
  Future<Either<Failure, PageResult<Appartement>>> getPage({
    int page,
    int size,
    int? immeubleId,
    StatutAppartement? statut,
    String? recherche,
  });

  Future<Either<Failure, Appartement>> getById(int id);

  Future<Either<Failure, Appartement>> create(Appartement appartement);

  Future<Either<Failure, Appartement>> update(int id, Appartement appartement);

  Future<Either<Failure, void>> delete(int id);
}
