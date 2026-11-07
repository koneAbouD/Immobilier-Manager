import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/immeuble.dart';
import '../entities/photo_bien.dart';

abstract interface class ImmeubleRepository {
  Future<Either<Failure, List<Immeuble>>> getAll();

  Future<Either<Failure, PageResult<Immeuble>>> getPage({
    int page,
    int size,
    String? recherche,
  });

  Future<Either<Failure, Immeuble>> getById(int id);

  Future<Either<Failure, Immeuble>> create(Immeuble immeuble);

  Future<Either<Failure, Immeuble>> update(int id, Immeuble immeuble);

  Future<Either<Failure, void>> delete(int id);

  Future<Either<Failure, List<PhotoBien>>> getPhotos(int id);

  Future<Either<Failure, PhotoBien>> ajouterPhoto(int id,
      {required Uint8List contenu, required String nomFichier, required String type});

  Future<Either<Failure, Uint8List>> telechargerPhoto(int id, int photoId);

  Future<Either<Failure, void>> supprimerPhoto(int id, int photoId);
}
