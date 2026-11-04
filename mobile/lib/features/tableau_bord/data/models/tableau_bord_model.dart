import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tableau_bord.dart';

abstract final class TableauBordModel {
  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  static TableauBord fromJson(Map<String, dynamic> json) => TableauBord(
        periode: parseDate(json['periode']) ?? DateTime.now(),
        nombreImmeubles: _int(json['nombreImmeubles']),
        nombreAppartements: _int(json['nombreAppartements']),
        nombreAppartementsOccupes: _int(json['nombreAppartementsOccupes']),
        tauxOccupation: _int(json['tauxOccupation']),
        nombreLocatairesActifs: _int(json['nombreLocatairesActifs']),
        loyersAttendus: parseNum(json['loyersAttendus']) ?? 0,
        loyersEncaisses: parseNum(json['loyersEncaisses']) ?? 0,
        tauxRecouvrement: _int(json['tauxRecouvrement']),
        impayes: parseNum(json['impayes']) ?? 0,
        nombreEcheancesEnRetard: _int(json['nombreEcheancesEnRetard']),
        maintenancesOuvertes: _int(json['maintenancesOuvertes']),
        maintenancesUrgentes: _int(json['maintenancesUrgentes']),
      );
}
