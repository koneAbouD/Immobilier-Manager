import '../../../../core/utils/formatters.dart';
import '../../domain/entities/locataire.dart';

abstract final class LocataireModel {
  static Locataire fromJson(Map<String, dynamic> json) => Locataire(
        id: json['id'] as int?,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        telephone: json['telephone'] as String,
        email: json['email'] as String?,
        typePiece: TypePiece.fromCode(json['typePiece'] as String?),
        numeroPiece: json['numeroPiece'] as String?,
        profession: json['profession'] as String?,
        dateNaissance: parseDate(json['dateNaissance']),
        adresse: json['adresse'] as String?,
        contactUrgenceNom: json['contactUrgenceNom'] as String?,
        contactUrgenceTelephone: json['contactUrgenceTelephone'] as String?,
      );

  static Map<String, dynamic> toJson(Locataire l) => {
        'nom': l.nom,
        'prenom': l.prenom,
        'telephone': l.telephone,
        'email': l.email,
        'typePiece': l.typePiece?.code,
        'numeroPiece': l.numeroPiece,
        'profession': l.profession,
        'dateNaissance': l.dateNaissance == null ? null : isoDate(l.dateNaissance!),
        'adresse': l.adresse,
        'contactUrgenceNom': l.contactUrgenceNom,
        'contactUrgenceTelephone': l.contactUrgenceTelephone,
      };
}
