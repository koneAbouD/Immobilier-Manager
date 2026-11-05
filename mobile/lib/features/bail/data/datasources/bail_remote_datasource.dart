import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/bail.dart';
import '../models/bail_model.dart';

class BailRemoteDatasource {
  final ApiClient _client;
  const BailRemoteDatasource(this._client);

  Future<PageResult<Bail>> getPage({
    int page = 0,
    int size = 20,
    int? appartementId,
    int? locataireId,
    StatutBail? statut,
    String? recherche,
  }) async {
    final data = await _client.get('/baux/page', query: {
      'page': '$page',
      'size': '$size',
      if (appartementId != null) 'appartementId': '$appartementId',
      if (locataireId != null) 'locataireId': '$locataireId',
      if (statut != null) 'statut': statut.code,
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, BailModel.fromJson);
  }

  Future<Bail> getById(int id) async =>
      BailModel.fromJson(await _client.get('/baux/$id') as Map<String, dynamic>);

  Future<Bail> create(Bail b) async =>
      BailModel.fromJson(await _client.post('/baux', BailModel.toJson(b)) as Map<String, dynamic>);

  Future<Bail> update(int id, Bail b) async => BailModel.fromJson(
      await _client.put('/baux/$id', BailModel.toJson(b)) as Map<String, dynamic>);

  Future<Bail> resilier(int id, {DateTime? date, required String motif}) async =>
      BailModel.fromJson(await _client.patch('/baux/$id/resilier', {
        'dateResiliation': date == null ? null : isoDate(date),
        'motif': motif,
      }) as Map<String, dynamic>);

  /// Contrat PDF prérempli, régénéré à chaque appel.
  Future<Uint8List> genererContrat(int id) => _client.getBytes('/baux/$id/contrat');

  Future<Bail> deposerContratSigne(int id,
          {required Uint8List contenu, required String nomFichier, required String type}) async =>
      BailModel.fromJson(await _client.postFichier('/baux/$id/contrat-signe',
          champ: 'fichier', contenu: contenu, nomFichier: nomFichier, type: type) as Map<String, dynamic>);

  Future<Uint8List> telechargerContratSigne(int id) => _client.getBytes('/baux/$id/contrat-signe');
}
