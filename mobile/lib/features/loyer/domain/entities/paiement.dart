enum ModePaiement {
  especes('ESPECES', 'Espèces'),
  mobileMoney('MOBILE_MONEY', 'Mobile Money'),
  virement('VIREMENT', 'Virement'),
  cheque('CHEQUE', 'Chèque');

  final String code;
  final String libelle;
  const ModePaiement(this.code, this.libelle);

  static ModePaiement fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => ModePaiement.especes);
}

class Paiement {
  final int? id;
  final int? echeanceId;
  final DateTime? periode;
  final String? locataireNom;
  final String? appartementReference;
  final String? immeubleNom;
  final double montant;
  final DateTime? datePaiement;
  final ModePaiement modePaiement;
  final String? reference;
  final String? commentaire;
  final bool annule;
  final String? motifAnnulation;
  final String? annulePar;
  final String? encaissePar;

  const Paiement({
    this.id,
    this.echeanceId,
    this.periode,
    this.locataireNom,
    this.appartementReference,
    this.immeubleNom,
    required this.montant,
    this.datePaiement,
    required this.modePaiement,
    this.reference,
    this.commentaire,
    this.annule = false,
    this.motifAnnulation,
    this.annulePar,
    this.encaissePar,
  });
}
