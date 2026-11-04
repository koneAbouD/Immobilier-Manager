import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/maintenance.dart';

abstract interface class MaintenanceRepository {
  Future<Either<Failure, PageResult<Maintenance>>> getPage({
    int page,
    int size,
    int? immeubleId,
    StatutMaintenance? statut,
    PrioriteMaintenance? priorite,
    String? recherche,
  });

  Future<Either<Failure, Maintenance>> getById(int id);

  Future<Either<Failure, Maintenance>> signaler(Maintenance maintenance);

  Future<Either<Failure, Maintenance>> update(int id, Maintenance maintenance);

  Future<Either<Failure, Maintenance>> demarrer(int id);

  Future<Either<Failure, Maintenance>> terminer(int id, {double? coutReel, DateTime? date});

  Future<Either<Failure, Maintenance>> annuler(int id, String motif);

  Future<Either<Failure, void>> delete(int id);
}
