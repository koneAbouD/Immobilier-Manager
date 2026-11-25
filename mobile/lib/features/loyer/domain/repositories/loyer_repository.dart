import 'dart:typed_data';

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
    int? immeubleId,
    DateTime? periode,
    StatutEcheance? statut,
    bool aEncaisser,
    bool enRetard,
  });

  /// Attendu et encaissé des loyers d'un mois, pour tous les biens ou un seul.
  Future<Either<Failure, ResumeLoyers>> getResume({required DateTime periode, int? immeubleId});

  Future<Either<Failure, Echeance>> getEcheance(int id);

  Future<Either<Failure, Paiement>> encaisser(int echeanceId, Paiement paiement);

  Future<Either<Failure, List<Paiement>>> getPaiementsEcheance(int echeanceId);

  Future<Either<Failure, PageResult<Paiement>>> getPaiements({
    int page,
    int size,
    int? bailId,
    int? locataireId,
  });

  Future<Either<Failure, Paiement>> annulerPaiement(int paiementId, String motif);

  /// Émet les loyers manquants jusqu'au mois [jusquA] (par défaut le dernier
  /// mois émis automatiquement), pour un bail ou pour tous ; renvoie le nombre créé.
  Future<Either<Failure, int>> genererEcheances({DateTime? jusquA, int? bailId});

  /// Quittance PDF d'un paiement (refusée pour un paiement annulé).
  Future<Either<Failure, Uint8List>> quittance(int paiementId);
}
