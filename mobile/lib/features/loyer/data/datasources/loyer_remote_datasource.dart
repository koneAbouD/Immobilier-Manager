import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';
import '../models/loyer_models.dart';

class LoyerRemoteDatasource {
  final ApiClient _client;
  const LoyerRemoteDatasource(this._client);

  Future<PageResult<Echeance>> getEcheances({
    int page = 0,
    int size = 20,
    int? bailId,
    int? locataireId,
    DateTime? periode,
    StatutEcheance? statut,
    bool aEncaisser = false,
    bool enRetard = false,
  }) async {
    final data = await _client.get('/loyers/echeances/page', query: {
      'page': '$page',
      'size': '$size',
      if (bailId != null) 'bailId': '$bailId',
      if (locataireId != null) 'locataireId': '$locataireId',
      if (periode != null) 'periode': isoMois(periode),
      if (statut != null) 'statut': statut.code,
      if (aEncaisser) 'aEncaisser': 'true',
      if (enRetard) 'enRetard': 'true',
    });
    return PageResult.fromJson(data as Map<String, dynamic>, EcheanceModel.fromJson);
  }

  Future<Echeance> getEcheance(int id) async =>
      EcheanceModel.fromJson(await _client.get('/loyers/echeances/$id') as Map<String, dynamic>);

  Future<Paiement> encaisser(int echeanceId, Paiement p) async => PaiementModel.fromJson(
      await _client.post('/loyers/echeances/$echeanceId/paiements', PaiementModel.toJson(p))
          as Map<String, dynamic>);

  Future<List<Paiement>> getPaiementsEcheance(int echeanceId) async {
    final data = await _client.get('/loyers/echeances/$echeanceId/paiements') as List;
    return data.map((e) => PaiementModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PageResult<Paiement>> getPaiements(
      {int page = 0, int size = 20, int? bailId, int? locataireId}) async {
    final data = await _client.get('/loyers/paiements/page', query: {
      'page': '$page',
      'size': '$size',
      if (bailId != null) 'bailId': '$bailId',
      if (locataireId != null) 'locataireId': '$locataireId',
    });
    return PageResult.fromJson(data as Map<String, dynamic>, PaiementModel.fromJson);
  }

  Future<Paiement> annulerPaiement(int paiementId, String motif) async =>
      PaiementModel.fromJson(await _client
          .patch('/loyers/paiements/$paiementId/annuler', {'motif': motif}) as Map<String, dynamic>);

  /// Émet les loyers manquants jusqu'au mois [jusquA] (par défaut le dernier
  /// mois émis automatiquement), pour un bail ou pour tous les baux actifs.
  Future<int> genererEcheances({DateTime? jusquA, int? bailId}) async {
    final query = {
      if (jusquA != null) 'jusquA': isoMois(jusquA),
      if (bailId != null) 'bailId': '$bailId',
    };
    final chemin = query.isEmpty
        ? '/loyers/echeances/generer'
        : '/loyers/echeances/generer?${Uri(queryParameters: query).query}';
    final data = await _client.post(chemin) as Map<String, dynamic>;
    return (data['nombreCreees'] as num).toInt();
  }

  /// Quittance PDF d'un paiement, produite à la demande par le serveur.
  Future<Uint8List> quittance(int paiementId) => _client.getBytes('/loyers/paiements/$paiementId/quittance');
}
