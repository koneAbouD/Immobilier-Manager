import '../../../../core/utils/formatters.dart';
import '../../../appartement/domain/entities/appartement.dart';
import '../../domain/entities/locataire_resume.dart';

abstract final class LocataireResumeModel {
  static LocataireResume fromJson(Map<String, dynamic> json) => LocataireResume(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String? ?? '',
        nomComplet: json['nomComplet'] as String? ?? '',
        telephone: json['telephone'] as String? ?? '',
        profession: json['profession'] as String?,
        situation: SituationLocataire.fromCode(json['situation'] as String?),
        nombreBauxActifs: (json['nombreBauxActifs'] as num?)?.toInt() ?? 0,
        logementReference: json['logementReference'] as String?,
        immeubleNom: json['immeubleNom'] as String?,
        typeLogement:
            json['typeLogement'] == null ? null : TypeLogement.fromCode(json['typeLogement'] as String),
        montantEnRetard: parseNum(json['montantEnRetard']) ?? 0,
        joursRetard: (json['joursRetard'] as num?)?.toInt() ?? 0,
        contratsASigner: (json['contratsASigner'] as num?)?.toInt() ?? 0,
      );

  static ComptesSituations comptesFromJson(Map<String, dynamic> json) => ComptesSituations(
        total: (json['total'] as num?)?.toInt() ?? 0,
        enRetard: (json['enRetard'] as num?)?.toInt() ?? 0,
        aJour: (json['aJour'] as num?)?.toInt() ?? 0,
        sansBail: (json['sansBail'] as num?)?.toInt() ?? 0,
      );
}
