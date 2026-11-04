import '../../../../core/utils/formatters.dart';
import '../../domain/entities/maintenance.dart';

abstract final class MaintenanceModel {
  static Maintenance fromJson(Map<String, dynamic> json) => Maintenance(
        id: json['id'] as int?,
        immeubleId: json['immeubleId'] as int?,
        immeubleNom: json['immeubleNom'] as String?,
        appartementId: json['appartementId'] as int?,
        appartementReference: json['appartementReference'] as String?,
        titre: json['titre'] as String,
        description: json['description'] as String?,
        categorie: CategorieMaintenance.fromCode(json['categorie'] as String?),
        priorite: PrioriteMaintenance.fromCode(json['priorite'] as String?),
        statut: StatutMaintenance.fromCode(json['statut'] as String?),
        dateSignalement: parseDate(json['dateSignalement']),
        datePrevue: parseDate(json['datePrevue']),
        dateRealisation: parseDate(json['dateRealisation']),
        prestataire: json['prestataire'] as String?,
        coutEstime: parseNum(json['coutEstime']),
        coutReel: parseNum(json['coutReel']),
        motifAnnulation: json['motifAnnulation'] as String?,
        annulePar: json['annulePar'] as String?,
      );

  static Map<String, dynamic> toJson(Maintenance m) => {
        'immeubleId': m.immeubleId,
        'appartementId': m.appartementId,
        'titre': m.titre,
        'description': m.description,
        'categorie': m.categorie.code,
        'priorite': m.priorite.code,
        'dateSignalement': m.dateSignalement == null ? null : isoDate(m.dateSignalement!),
        'datePrevue': m.datePrevue == null ? null : isoDate(m.datePrevue!),
        'prestataire': m.prestataire,
        'coutEstime': m.coutEstime,
      };
}
