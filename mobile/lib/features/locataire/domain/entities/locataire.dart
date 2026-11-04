enum TypePiece {
  cni('CNI', 'Carte nationale d\'identité'),
  passeport('PASSEPORT', 'Passeport'),
  carteConsulaire('CARTE_CONSULAIRE', 'Carte consulaire'),
  permisConduire('PERMIS_CONDUIRE', 'Permis de conduire'),
  carteSejour('CARTE_SEJOUR', 'Carte de séjour'),
  autre('AUTRE', 'Autre');

  final String code;
  final String libelle;
  const TypePiece(this.code, this.libelle);

  static TypePiece? fromCode(String? code) =>
      code == null ? null : values.where((v) => v.code == code).firstOrNull;
}

class Locataire {
  final int? id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final TypePiece? typePiece;
  final String? numeroPiece;
  final String? profession;
  final DateTime? dateNaissance;
  final String? adresse;
  final String? contactUrgenceNom;
  final String? contactUrgenceTelephone;

  const Locataire({
    this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.typePiece,
    this.numeroPiece,
    this.profession,
    this.dateNaissance,
    this.adresse,
    this.contactUrgenceNom,
    this.contactUrgenceTelephone,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();
}
