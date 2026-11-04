import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';
import '../../domain/repositories/loyer_repository.dart';
import '../datasources/loyer_remote_datasource.dart';

class LoyerRepositoryImpl implements LoyerRepository {
  final LoyerRemoteDatasource _ds;
  const LoyerRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, PageResult<Echeance>>> getEcheances({
    int page = 0,
    int size = 20,
    int? bailId,
    int? locataireId,
    DateTime? periode,
    StatutEcheance? statut,
    bool aEncaisser = false,
    bool enRetard = false,
  }) =>
      guard(() => _ds.getEcheances(
            page: page,
            size: size,
            bailId: bailId,
            locataireId: locataireId,
            periode: periode,
            statut: statut,
            aEncaisser: aEncaisser,
            enRetard: enRetard,
          ));

  @override
  Future<Either<Failure, Paiement>> encaisser(int echeanceId, Paiement paiement) =>
      guard(() => _ds.encaisser(echeanceId, paiement));

  @override
  Future<Either<Failure, List<Paiement>>> getPaiementsEcheance(int echeanceId) =>
      guard(() => _ds.getPaiementsEcheance(echeanceId));

  @override
  Future<Either<Failure, PageResult<Paiement>>> getPaiements(
          {int page = 0, int size = 20, int? bailId, int? locataireId}) =>
      guard(() => _ds.getPaiements(
          page: page, size: size, bailId: bailId, locataireId: locataireId));

  @override
  Future<Either<Failure, Paiement>> annulerPaiement(int paiementId, String motif) =>
      guard(() => _ds.annulerPaiement(paiementId, motif));

  @override
  Future<Either<Failure, int>> genererEcheances() => guard(_ds.genererEcheances);
}
