class Immeuble {
  final int? id;
  final String nom;
  final String? adresse;
  final String? commune;
  final String? ville;
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
    this.adresse,
    this.commune,
    this.ville,
    this.nombreEtages,
    this.anneeConstruction,
    this.description,
    this.nombreAppartements = 0,
    this.nombreOccupes = 0,
    this.nombreLibres = 0,
  });

  String get localisation =>
      [commune, ville].where((s) => s != null && s.isNotEmpty).join(', ');

  int get tauxOccupation =>
      nombreAppartements == 0 ? 0 : (100 * nombreOccupes / nombreAppartements).round();
}
