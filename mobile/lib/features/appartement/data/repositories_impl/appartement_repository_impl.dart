import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/appartement.dart';
import '../../domain/repositories/appartement_repository.dart';
import '../datasources/appartement_remote_datasource.dart';

class AppartementRepositoryImpl implements AppartementRepository {
  final AppartementRemoteDatasource _ds;
  const AppartementRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, PageResult<Appartement>>> getPage({
    int page = 0,
    int size = 20,
    int? immeubleId,
    StatutAppartement? statut,
    String? recherche,
  }) =>
      guard(() => _ds.getPage(
          page: page, size: size, immeubleId: immeubleId, statut: statut, recherche: recherche));

  @override
  Future<Either<Failure, Appartement>> getById(int id) => guard(() => _ds.getById(id));

  @override
  Future<Either<Failure, Appartement>> create(Appartement a) => guard(() => _ds.create(a));

  @override
  Future<Either<Failure, Appartement>> update(int id, Appartement a) =>
      guard(() => _ds.update(id, a));

  @override
  Future<Either<Failure, void>> delete(int id) => guard(() => _ds.delete(id));
}
