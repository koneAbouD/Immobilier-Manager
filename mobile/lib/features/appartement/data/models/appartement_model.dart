import '../../../../core/utils/formatters.dart';
import '../../domain/entities/appartement.dart';

abstract final class AppartementModel {
  static Appartement fromJson(Map<String, dynamic> json) => Appartement(
        id: json['id'] as int?,
        immeubleId: json['immeubleId'] as int,
        immeubleNom: json['immeubleNom'] as String?,
        reference: json['reference'] as String,
        etage: json['etage'] as int?,
        type: TypeLogement.fromCode(json['type'] as String?),
        superficie: parseNum(json['superficie']),
        nombrePieces: json['nombrePieces'] as int?,
        loyerMensuel: parseNum(json['loyerMensuel']) ?? 0,
        charges: parseNum(json['charges']) ?? 0,
        statut: StatutAppartement.fromCode(json['statut'] as String?),
        description: json['description'] as String?,
      );

  static Map<String, dynamic> toJson(Appartement a) => {
        'immeubleId': a.immeubleId,
        'reference': a.reference,
        'etage': a.etage,
        'type': a.type.code,
        'superficie': a.superficie,
        'nombrePieces': a.nombrePieces,
        'loyerMensuel': a.loyerMensuel,
        'charges': a.charges,
        'statut': a.statut.code,
        'description': a.description,
      };
}
