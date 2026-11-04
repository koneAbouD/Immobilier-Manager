import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tableau_bord.dart';
import '../models/tableau_bord_model.dart';

class TableauBordRemoteDatasource {
  final ApiClient _client;
  const TableauBordRemoteDatasource(this._client);

  Future<TableauBord> get({DateTime? periode}) async {
    final data = await _client.get('/tableau-bord',
        query: {if (periode != null) 'periode': isoMois(periode)});
    return TableauBordModel.fromJson(data as Map<String, dynamic>);
  }
}
