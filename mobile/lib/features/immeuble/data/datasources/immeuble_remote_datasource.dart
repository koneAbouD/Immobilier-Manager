import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/immeuble.dart';
import '../../domain/entities/photo_bien.dart';
import '../models/immeuble_model.dart';

class ImmeubleRemoteDatasource {
  final ApiClient _client;
  const ImmeubleRemoteDatasource(this._client);

  Future<List<Immeuble>> getAll() async {
    final data = await _client.get('/immeubles') as List;
    return data.map((e) => ImmeubleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PageResult<Immeuble>> getPage({int page = 0, int size = 20, String? recherche}) async {
    final data = await _client.get('/immeubles/page', query: {
      'page': '$page',
      'size': '$size',
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, ImmeubleModel.fromJson);
  }

  Future<Immeuble> getById(int id) async =>
      ImmeubleModel.fromJson(await _client.get('/immeubles/$id') as Map<String, dynamic>);

  Future<Immeuble> create(Immeuble i) async => ImmeubleModel.fromJson(
      await _client.post('/immeubles', ImmeubleModel.toJson(i)) as Map<String, dynamic>);

  Future<Immeuble> update(int id, Immeuble i) async => ImmeubleModel.fromJson(
      await _client.put('/immeubles/$id', ImmeubleModel.toJson(i)) as Map<String, dynamic>);

  Future<void> delete(int id) => _client.delete('/immeubles/$id');

  Future<List<PhotoBien>> getPhotos(int id) async {
    final data = await _client.get('/immeubles/$id/photos') as List;
    return data.map((e) => _photo(e as Map<String, dynamic>)).toList();
  }

  Future<PhotoBien> ajouterPhoto(int id,
          {required Uint8List contenu, required String nomFichier, required String type}) async =>
      _photo(await _client.postFichier('/immeubles/$id/photos',
          champ: 'fichier', contenu: contenu, nomFichier: nomFichier, type: type) as Map<String, dynamic>);

  Future<Uint8List> telechargerPhoto(int id, int photoId) => _client.getBytes('/immeubles/$id/photos/$photoId');

  Future<void> supprimerPhoto(int id, int photoId) => _client.delete('/immeubles/$id/photos/$photoId');

  static PhotoBien _photo(Map<String, dynamic> json) => PhotoBien(
        id: json['id'] as int,
        nom: json['nom'] as String?,
        type: json['type'] as String? ?? 'image/jpeg',
        taille: (json['taille'] as num?)?.toInt(),
        ajouteeLe: parseDate(json['ajouteeLe']),
        ajouteePar: json['ajouteePar'] as String?,
      );
}
