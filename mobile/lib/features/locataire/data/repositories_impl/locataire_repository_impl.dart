import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/locataire.dart';
import '../../domain/repositories/locataire_repository.dart';
import '../datasources/locataire_remote_datasource.dart';

class LocataireRepositoryImpl implements LocataireRepository {
  final LocataireRemoteDatasource _ds;
  const LocataireRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, PageResult<Locataire>>> getPage(
          {int page = 0, int size = 20, String? recherche}) =>
      guard(() => _ds.getPage(page: page, size: size, recherche: recherche));

  @override
  Future<Either<Failure, Locataire>> getById(int id) => guard(() => _ds.getById(id));

  @override
  Future<Either<Failure, Locataire>> create(Locataire l) => guard(() => _ds.create(l));

  @override
  Future<Either<Failure, Locataire>> update(int id, Locataire l) =>
      guard(() => _ds.update(id, l));

  @override
  Future<Either<Failure, void>> delete(int id) => guard(() => _ds.delete(id));
}
