import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/locataire.dart';
import '../../domain/entities/locataire_resume.dart';
import '../models/locataire_model.dart';
import '../models/locataire_resume_model.dart';

class LocataireRemoteDatasource {
  final ApiClient _client;
  const LocataireRemoteDatasource(this._client);

  Future<PageResult<Locataire>> getPage({int page = 0, int size = 20, String? recherche}) async {
    final data = await _client.get('/locataires/page', query: {
      'page': '$page',
      'size': '$size',
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, LocataireModel.fromJson);
  }

  Future<PageResult<LocataireResume>> getResumes(
      {int page = 0, int size = 20, String? recherche, SituationLocataire? situation}) async {
    final data = await _client.get('/locataires/resumes/page', query: {
      'page': '$page',
      'size': '$size',
      if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
      if (situation != null) 'situation': situation.code,
    });
    return PageResult.fromJson(data as Map<String, dynamic>, LocataireResumeModel.fromJson);
  }

  Future<ComptesSituations> getComptes({String? recherche}) async =>
      LocataireResumeModel.comptesFromJson(await _client.get('/locataires/resumes/comptes', query: {
        if (recherche != null && recherche.isNotEmpty) 'recherche': recherche,
      }) as Map<String, dynamic>);

  Future<Locataire> getById(int id) async =>
      LocataireModel.fromJson(await _client.get('/locataires/$id') as Map<String, dynamic>);

  Future<Locataire> create(Locataire l) async => LocataireModel.fromJson(
      await _client.post('/locataires', LocataireModel.toJson(l)) as Map<String, dynamic>);

  Future<Locataire> update(int id, Locataire l) async => LocataireModel.fromJson(
      await _client.put('/locataires/$id', LocataireModel.toJson(l)) as Map<String, dynamic>);

  Future<void> delete(int id) => _client.delete('/locataires/$id');
}
