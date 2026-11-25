import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/entree_journal.dart';

class JournalRemoteDatasource {
  final ApiClient _client;
  const JournalRemoteDatasource(this._client);

  Future<PageResult<EntreeJournal>> getPage({
    int page = 0,
    int size = 20,
    TypeEntiteJournal? type,
    ActionJournal? action,
    String? recherche,
  }) async {
    final data = await _client.get('/journal/page', query: {
      'page': '$page',
      'size': '$size',
      if (type != null) 'type': type.code,
      if (action != null) 'action': action.code,
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, EntreeJournal.fromJson);
  }
}
