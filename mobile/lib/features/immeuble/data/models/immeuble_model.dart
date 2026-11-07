import '../../../../core/utils/formatters.dart';
import '../../domain/entities/immeuble.dart';

/// Miroir de `ImmeubleResponse` / `ImmeubleRequest` côté backend.
abstract final class ImmeubleModel {
  static Immeuble fromJson(Map<String, dynamic> json) => Immeuble(
        id: json['id'] as int?,
        nom: json['nom'] as String,
        type: TypeBien.fromCode(json['type'] as String?),
        adresse: json['adresse'] as String?,
        commune: json['commune'] as String?,
        ville: json['ville'] as String?,
        latitude: parseNum(json['latitude']),
        longitude: parseNum(json['longitude']),
        nombreEtages: json['nombreEtages'] as int?,
        anneeConstruction: json['anneeConstruction'] as int?,
        description: json['description'] as String?,
        nombreAppartements: (json['nombreAppartements'] as num?)?.toInt() ?? 0,
        nombreOccupes: (json['nombreOccupes'] as num?)?.toInt() ?? 0,
        nombreLibres: (json['nombreLibres'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> toJson(Immeuble i) => {
        'nom': i.nom,
        'type': i.type.code,
        'adresse': i.adresse,
        'commune': i.commune,
        'ville': i.ville,
        'latitude': i.latitude,
        'longitude': i.longitude,
        'nombreEtages': i.nombreEtages,
        'anneeConstruction': i.anneeConstruction,
        'description': i.description,
      };
}
