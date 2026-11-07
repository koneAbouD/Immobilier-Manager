/// Photo d'un bien ; le fichier se télécharge à part.
class PhotoBien {
  final int id;
  final String? nom;
  final String type;
  final int? taille;
  final DateTime? ajouteeLe;
  final String? ajouteePar;

  const PhotoBien({
    required this.id,
    this.nom,
    required this.type,
    this.taille,
    this.ajouteeLe,
    this.ajouteePar,
  });
}
