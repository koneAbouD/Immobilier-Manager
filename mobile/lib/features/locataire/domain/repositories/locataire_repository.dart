import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/locataire.dart';
import '../entities/locataire_resume.dart';

abstract interface class LocataireRepository {
  Future<Either<Failure, PageResult<Locataire>>> getPage({int page, int size, String? recherche});

  Future<Either<Failure, PageResult<LocataireResume>>> getResumes(
      {int page, int size, String? recherche, SituationLocataire? situation});

  Future<Either<Failure, ComptesSituations>> getComptes({String? recherche});

  Future<Either<Failure, Locataire>> getById(int id);

  Future<Either<Failure, Locataire>> create(Locataire locataire);

  Future<Either<Failure, Locataire>> update(int id, Locataire locataire);

  Future<Either<Failure, void>> delete(int id);
}
