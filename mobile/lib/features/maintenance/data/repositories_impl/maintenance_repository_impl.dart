import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../datasources/maintenance_remote_datasource.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final MaintenanceRemoteDatasource _ds;
  const MaintenanceRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, PageResult<Maintenance>>> getPage({
    int page = 0,
    int size = 20,
    int? immeubleId,
    StatutMaintenance? statut,
    PrioriteMaintenance? priorite,
    String? recherche,
  }) =>
      guard(() => _ds.getPage(
            page: page,
            size: size,
            immeubleId: immeubleId,
            statut: statut,
            priorite: priorite,
            recherche: recherche,
          ));

  @override
  Future<Either<Failure, Maintenance>> getById(int id) => guard(() => _ds.getById(id));

  @override
  Future<Either<Failure, Maintenance>> signaler(Maintenance m) => guard(() => _ds.signaler(m));

  @override
  Future<Either<Failure, Maintenance>> update(int id, Maintenance m) =>
      guard(() => _ds.update(id, m));

  @override
  Future<Either<Failure, Maintenance>> demarrer(int id) => guard(() => _ds.demarrer(id));

  @override
  Future<Either<Failure, Maintenance>> terminer(int id, {double? coutReel, DateTime? date}) =>
      guard(() => _ds.terminer(id, coutReel: coutReel, date: date));

  @override
  Future<Either<Failure, Maintenance>> annuler(int id, String motif) =>
      guard(() => _ds.annuler(id, motif));

  @override
  Future<Either<Failure, void>> delete(int id) => guard(() => _ds.delete(id));
}
