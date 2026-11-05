import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/locataire.dart';
import '../../domain/entities/locataire_resume.dart';
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
  Future<Either<Failure, PageResult<LocataireResume>>> getResumes(
          {int page = 0, int size = 20, String? recherche, SituationLocataire? situation}) =>
      guard(() => _ds.getResumes(page: page, size: size, recherche: recherche, situation: situation));

  @override
  Future<Either<Failure, ComptesSituations>> getComptes({String? recherche}) =>
      guard(() => _ds.getComptes(recherche: recherche));

  @override
  Future<Either<Failure, Locataire>> getById(int id) => guard(() => _ds.getById(id));

  @override
  Future<Either<Failure, Locataire>> create(Locataire l) => guard(() => _ds.create(l));

  @override
  Future<Either<Failure, Locataire>> update(int id, Locataire l) =>
      guard(() => _ds.update(id, l));

  @override
  Future<Either<Failure, void>> delete(int id) => guard(() => _ds.delete(id));

  @override
  Future<Either<Failure, Locataire>> deposerPieceIdentite(int id,
          {required Uint8List contenu, required String nomFichier, required String type}) =>
      guard(() => _ds.deposerPieceIdentite(id, contenu: contenu, nomFichier: nomFichier, type: type));

  @override
  Future<Either<Failure, Uint8List>> telechargerPieceIdentite(int id) =>
      guard(() => _ds.telechargerPieceIdentite(id));
}
