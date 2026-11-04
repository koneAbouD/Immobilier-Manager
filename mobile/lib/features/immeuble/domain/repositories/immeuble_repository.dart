import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/immeuble.dart';

abstract interface class ImmeubleRepository {
  Future<Either<Failure, List<Immeuble>>> getAll();

  Future<Either<Failure, PageResult<Immeuble>>> getPage({
    int page,
    int size,
    String? recherche,
  });

  Future<Either<Failure, Immeuble>> getById(int id);

  Future<Either<Failure, Immeuble>> create(Immeuble immeuble);

  Future<Either<Failure, Immeuble>> update(int id, Immeuble immeuble);

  Future<Either<Failure, void>> delete(int id);
}
