import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/bail.dart';
import '../../domain/repositories/bail_repository.dart';
import '../datasources/bail_remote_datasource.dart';

class BailRepositoryImpl implements BailRepository {
  final BailRemoteDatasource _ds;
  const BailRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, PageResult<Bail>>> getPage({
    int page = 0,
    int size = 20,
    int? appartementId,
    int? locataireId,
    StatutBail? statut,
    String? recherche,
  }) =>
      guard(() => _ds.getPage(
            page: page,
            size: size,
            appartementId: appartementId,
            locataireId: locataireId,
            statut: statut,
            recherche: recherche,
          ));

  @override
  Future<Either<Failure, Bail>> getById(int id) => guard(() => _ds.getById(id));

  @override
  Future<Either<Failure, Bail>> create(Bail bail) => guard(() => _ds.create(bail));

  @override
  Future<Either<Failure, Bail>> update(int id, Bail bail) => guard(() => _ds.update(id, bail));

  @override
  Future<Either<Failure, Bail>> resilier(int id, {DateTime? date, required String motif}) =>
      guard(() => _ds.resilier(id, date: date, motif: motif));
}
