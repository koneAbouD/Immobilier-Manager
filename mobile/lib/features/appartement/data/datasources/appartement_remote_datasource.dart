import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/appartement.dart';
import '../models/appartement_model.dart';

class AppartementRemoteDatasource {
  final ApiClient _client;
  const AppartementRemoteDatasource(this._client);

  Future<PageResult<Appartement>> getPage({
    int page = 0,
    int size = 20,
    int? immeubleId,
    StatutAppartement? statut,
    String? recherche,
  }) async {
    final data = await _client.get('/appartements/page', query: {
      'page': '$page',
      'size': '$size',
      if (immeubleId != null) 'immeubleId': '$immeubleId',
      if (statut != null) 'statut': statut.code,
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, AppartementModel.fromJson);
  }

  Future<Appartement> getById(int id) async => AppartementModel.fromJson(
      await _client.get('/appartements/$id') as Map<String, dynamic>);

  Future<Appartement> create(Appartement a) async => AppartementModel.fromJson(
      await _client.post('/appartements', AppartementModel.toJson(a)) as Map<String, dynamic>);

  Future<Appartement> update(int id, Appartement a) async => AppartementModel.fromJson(
      await _client.put('/appartements/$id', AppartementModel.toJson(a))
          as Map<String, dynamic>);

  Future<void> delete(int id) => _client.delete('/appartements/$id');
}
