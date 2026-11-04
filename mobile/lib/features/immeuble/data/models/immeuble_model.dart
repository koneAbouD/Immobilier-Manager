import '../../domain/entities/immeuble.dart';

/// Miroir de `ImmeubleResponse` / `ImmeubleRequest` côté backend.
abstract final class ImmeubleModel {
  static Immeuble fromJson(Map<String, dynamic> json) => Immeuble(
        id: json['id'] as int?,
        nom: json['nom'] as String,
        adresse: json['adresse'] as String?,
        commune: json['commune'] as String?,
        ville: json['ville'] as String?,
        nombreEtages: json['nombreEtages'] as int?,
        anneeConstruction: json['anneeConstruction'] as int?,
        description: json['description'] as String?,
        nombreAppartements: (json['nombreAppartements'] as num?)?.toInt() ?? 0,
        nombreOccupes: (json['nombreOccupes'] as num?)?.toInt() ?? 0,
        nombreLibres: (json['nombreLibres'] as num?)?.toInt() ?? 0,
      );

  static Map<String, dynamic> toJson(Immeuble i) => {
        'nom': i.nom,
        'adresse': i.adresse,
        'commune': i.commune,
        'ville': i.ville,
        'nombreEtages': i.nombreEtages,
        'anneeConstruction': i.anneeConstruction,
        'description': i.description,
      };
}
