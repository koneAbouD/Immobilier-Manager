import '../../../../core/utils/formatters.dart';
import '../../domain/entities/echeance.dart';
import '../../domain/entities/paiement.dart';

abstract final class EcheanceModel {
  static Echeance fromJson(Map<String, dynamic> json) => Echeance(
        id: json['id'] as int,
        bailId: json['bailId'] as int,
        bailReference: json['bailReference'] as String?,
        locataireId: json['locataireId'] as int,
        locataireNom: json['locataireNom'] as String? ?? '',
        locataireTelephone: json['locataireTelephone'] as String?,
        appartementReference: json['appartementReference'] as String?,
        immeubleNom: json['immeubleNom'] as String?,
        periode: parseDate(json['periode'])!,
        dateEcheance: parseDate(json['dateEcheance'])!,
        montantDu: parseNum(json['montantDu']) ?? 0,
        montantPaye: parseNum(json['montantPaye']) ?? 0,
        resteDu: parseNum(json['resteDu']) ?? 0,
        statut: StatutEcheance.fromCode(json['statut'] as String?),
        enRetard: json['enRetard'] as bool? ?? false,
      );
}

abstract final class PaiementModel {
  static Paiement fromJson(Map<String, dynamic> json) => Paiement(
        id: json['id'] as int?,
        echeanceId: json['echeanceId'] as int?,
        periode: parseDate(json['periode']),
        locataireNom: json['locataireNom'] as String?,
        appartementReference: json['appartementReference'] as String?,
        immeubleNom: json['immeubleNom'] as String?,
        montant: parseNum(json['montant']) ?? 0,
        datePaiement: parseDate(json['datePaiement']),
        modePaiement: ModePaiement.fromCode(json['modePaiement'] as String?),
        reference: json['reference'] as String?,
        commentaire: json['commentaire'] as String?,
        annule: json['annule'] as bool? ?? false,
        motifAnnulation: json['motifAnnulation'] as String?,
        annulePar: json['annulePar'] as String?,
        encaissePar: json['encaissePar'] as String?,
      );

  static Map<String, dynamic> toJson(Paiement p) => {
        'montant': p.montant,
        'datePaiement': p.datePaiement == null ? null : isoDate(p.datePaiement!),
        'modePaiement': p.modePaiement.code,
        'reference': p.reference,
        'commentaire': p.commentaire,
      };
}
