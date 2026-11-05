import '../../../../core/utils/formatters.dart';
import '../../domain/entities/bail.dart';

abstract final class BailModel {
  static Bail fromJson(Map<String, dynamic> json) => Bail(
        id: json['id'] as int?,
        reference: json['reference'] as String?,
        appartementId: json['appartementId'] as int,
        appartementReference: json['appartementReference'] as String?,
        immeubleId: json['immeubleId'] as int?,
        immeubleNom: json['immeubleNom'] as String?,
        locataireId: json['locataireId'] as int,
        locataireNom: json['locataireNom'] as String?,
        locataireTelephone: json['locataireTelephone'] as String?,
        dateDebut: parseDate(json['dateDebut'])!,
        dateFin: parseDate(json['dateFin']),
        loyerMensuel: parseNum(json['loyerMensuel']),
        charges: parseNum(json['charges']),
        montantMensuel: parseNum(json['montantMensuel']),
        depotGarantie: parseNum(json['depotGarantie']),
        jourEcheance: json['jourEcheance'] as int?,
        statut: StatutBail.fromCode(json['statut'] as String?),
        dateResiliation: parseDate(json['dateResiliation']),
        motifResiliation: json['motifResiliation'] as String?,
        resiliePar: json['resiliePar'] as String?,
        statutContrat: StatutContrat.fromCode(json['statutContrat'] as String?),
        contratGenereLe: parseDate(json['contratGenereLe']),
        contratSigneNom: json['contratSigneNom'] as String?,
        contratSigneType: json['contratSigneType'] as String?,
        contratSigneTaille: (json['contratSigneTaille'] as num?)?.toInt(),
        contratSigneLe: parseDate(json['contratSigneLe']),
        contratSignePar: json['contratSignePar'] as String?,
      );

  /// `BailRequest` (création) ; les identifiants sont ignorés en révision.
  static Map<String, dynamic> toJson(Bail b) => {
        'appartementId': b.appartementId,
        'locataireId': b.locataireId,
        'dateDebut': isoDate(b.dateDebut),
        'dateFin': b.dateFin == null ? null : isoDate(b.dateFin!),
        'loyerMensuel': b.loyerMensuel,
        'charges': b.charges,
        'depotGarantie': b.depotGarantie,
        'jourEcheance': b.jourEcheance,
      };
}
