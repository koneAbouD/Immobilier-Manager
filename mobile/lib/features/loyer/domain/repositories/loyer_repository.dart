import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/echeance.dart';
import '../entities/paiement.dart';

abstract interface class LoyerRepository {
  Future<Either<Failure, PageResult<Echeance>>> getEcheances({
    int page,
    int size,
    int? bailId,
    int? locataireId,
    DateTime? periode,
    StatutEcheance? statut,
    bool aEncaisser,
    bool enRetard,
  });

  Future<Either<Failure, Paiement>> encaisser(int echeanceId, Paiement paiement);

  Future<Either<Failure, List<Paiement>>> getPaiementsEcheance(int echeanceId);

  Future<Either<Failure, PageResult<Paiement>>> getPaiements({
    int page,
    int size,
    int? bailId,
    int? locataireId,
  });

  Future<Either<Failure, Paiement>> annulerPaiement(int paiementId, String motif);

  /// Émet les loyers manquants jusqu'au mois courant ; renvoie le nombre créé.
  Future<Either<Failure, int>> genererEcheances();
}
