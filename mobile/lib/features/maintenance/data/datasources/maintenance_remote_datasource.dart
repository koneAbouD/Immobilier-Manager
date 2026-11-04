import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/maintenance.dart';
import '../models/maintenance_model.dart';

class MaintenanceRemoteDatasource {
  final ApiClient _client;
  const MaintenanceRemoteDatasource(this._client);

  Future<PageResult<Maintenance>> getPage({
    int page = 0,
    int size = 20,
    int? immeubleId,
    StatutMaintenance? statut,
    PrioriteMaintenance? priorite,
    String? recherche,
  }) async {
    final data = await _client.get('/maintenances/page', query: {
      'page': '$page',
      'size': '$size',
      if (immeubleId != null) 'immeubleId': '$immeubleId',
      if (statut != null) 'statut': statut.code,
      if (priorite != null) 'priorite': priorite.code,
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, MaintenanceModel.fromJson);
  }

  Future<Maintenance> _map(Future<dynamic> appel) async =>
      MaintenanceModel.fromJson(await appel as Map<String, dynamic>);

  Future<Maintenance> getById(int id) => _map(_client.get('/maintenances/$id'));

  Future<Maintenance> signaler(Maintenance m) =>
      _map(_client.post('/maintenances', MaintenanceModel.toJson(m)));

  Future<Maintenance> update(int id, Maintenance m) =>
      _map(_client.put('/maintenances/$id', MaintenanceModel.toJson(m)));

  Future<Maintenance> demarrer(int id) => _map(_client.patch('/maintenances/$id/demarrer'));

  Future<Maintenance> terminer(int id, {double? coutReel, DateTime? date}) =>
      _map(_client.patch('/maintenances/$id/terminer', {
        'coutReel': coutReel,
        'dateRealisation': date == null ? null : isoDate(date),
      }));

  Future<Maintenance> annuler(int id, String motif) =>
      _map(_client.patch('/maintenances/$id/annuler', {'motif': motif}));

  Future<void> delete(int id) => _client.delete('/maintenances/$id');
}
