import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/immeuble.dart';
import '../../domain/entities/photo_bien.dart';
import '../../domain/repositories/immeuble_repository.dart';
import '../datasources/immeuble_remote_datasource.dart';

class ImmeubleRepositoryImpl implements ImmeubleRepository {
  final ImmeubleRemoteDatasource _ds;
  const ImmeubleRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<Immeuble>>> getAll() => guard(_ds.getAll);

  @override
  Future<Either<Failure, PageResult<Immeuble>>> getPage(
          {int page = 0, int size = 20, String? recherche}) =>
      guard(() => _ds.getPage(page: page, size: size, recherche: recherche));

  @override
  Future<Either<Failure, Immeuble>> getById(int id) => guard(() => _ds.getById(id));

  @override
  Future<Either<Failure, Immeuble>> create(Immeuble immeuble) =>
      guard(() => _ds.create(immeuble));

  @override
  Future<Either<Failure, Immeuble>> update(int id, Immeuble immeuble) =>
      guard(() => _ds.update(id, immeuble));

  @override
  Future<Either<Failure, void>> delete(int id) => guard(() => _ds.delete(id));

  @override
  Future<Either<Failure, List<PhotoBien>>> getPhotos(int id) => guard(() => _ds.getPhotos(id));

  @override
  Future<Either<Failure, PhotoBien>> ajouterPhoto(int id,
          {required Uint8List contenu, required String nomFichier, required String type}) =>
      guard(() => _ds.ajouterPhoto(id, contenu: contenu, nomFichier: nomFichier, type: type));

  @override
  Future<Either<Failure, Uint8List>> telechargerPhoto(int id, int photoId) =>
      guard(() => _ds.telechargerPhoto(id, photoId));

  @override
  Future<Either<Failure, void>> supprimerPhoto(int id, int photoId) => guard(() => _ds.supprimerPhoto(id, photoId));
}
