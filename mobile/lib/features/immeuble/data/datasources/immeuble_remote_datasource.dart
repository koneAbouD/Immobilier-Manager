import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/immeuble.dart';
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
}
