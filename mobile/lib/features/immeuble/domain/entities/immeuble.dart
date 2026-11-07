import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Nature d'un bien du parc.
enum TypeBien {
  immeuble('IMMEUBLE', 'Immeuble', Icons.apartment_rounded),
  courBasse('COUR_BASSE', 'Cour basse', Icons.holiday_village_outlined),
  terrain('TERRAIN', 'Terrain', Icons.landscape_outlined);

  final String code;
  final String libelle;
  final IconData icone;
  const TypeBien(this.code, this.libelle, this.icone);

  static TypeBien fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => TypeBien.immeuble);
}

/// Bien du parc (immeuble, cour basse, terrain), qui regroupe des logements.
class Immeuble {
  final int? id;
  final String nom;
  final TypeBien type;
  final String? adresse;
  final String? commune;
  final String? ville;

  /// Position relevée sur place ; nulles si non renseignée.
  final double? latitude;
  final double? longitude;
  final int? nombreEtages;
  final int? anneeConstruction;
  final String? description;

  /// Lecture seule : calculés par le backend depuis les logements.
  final int nombreAppartements;
  final int nombreOccupes;
  final int nombreLibres;

  const Immeuble({
    this.id,
    required this.nom,
    this.type = TypeBien.immeuble,
    this.adresse,
    this.commune,
    this.ville,
    this.latitude,
    this.longitude,
    this.nombreEtages,
    this.anneeConstruction,
    this.description,
    this.nombreAppartements = 0,
    this.nombreOccupes = 0,
    this.nombreLibres = 0,
  });

  LatLng? get position =>
      latitude == null || longitude == null ? null : LatLng(latitude!, longitude!);

  String get localisation =>
      [commune, ville].where((s) => s != null && s.isNotEmpty).join(', ');

  int get tauxOccupation =>
      nombreAppartements == 0 ? 0 : (100 * nombreOccupes / nombreAppartements).round();
}
