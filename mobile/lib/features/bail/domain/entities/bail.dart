import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../appartement/domain/entities/appartement.dart';

enum StatutBail {
  actif('ACTIF', 'Actif'),
  resilie('RESILIE', 'Résilié');

  final String code;
  final String libelle;
  const StatutBail(this.code, this.libelle);

  /// Teinte du statut, lue dans la charte : elle suit le thème clair/sombre.
  Color get couleur => switch (this) {
        actif => AppColors.positive,
        resilie => AppColors.hint,
      };

  static StatutBail fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => StatutBail.actif);
}

/// Régime du bail, choisi à la signature : il fixe le modèle du contrat PDF.
enum UsageBail {
  habitation('HABITATION', 'Habitation', 'Logement du locataire', Icons.bed_outlined),
  professionnel('PROFESSIONNEL', 'Professionnel', 'Activité, commerce, bureaux', Icons.work_outline_rounded);

  final String code;
  final String libelle;
  final String detail;
  final IconData icone;
  const UsageBail(this.code, this.libelle, this.detail, this.icone);

  /// Proposé à défaut : habitation pour un appartement, professionnel sinon.
  /// Même règle que le backend.
  static UsageBail parDefautPour(TypeLogement? type) =>
      type == null || type == TypeLogement.appartement ? habitation : professionnel;

  static UsageBail? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// Avancement du contrat écrit d'un bail.
enum StatutContrat {
  aGenerer('A_GENERER', 'Contrat à générer'),
  aSigner('A_SIGNER', 'Contrat à faire signer'),
  signe('SIGNE', 'Contrat signé');

  final String code;
  final String libelle;
  const StatutContrat(this.code, this.libelle);

  Color get couleur => switch (this) {
        aGenerer => AppColors.grey500,
        aSigner => AppColors.warning,
        signe => AppColors.positive,
      };

  IconData get icone => switch (this) {
        aGenerer => Icons.note_add_outlined,
        aSigner => Icons.pending_actions_outlined,
        signe => Icons.task_outlined,
      };

  static StatutContrat fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => StatutContrat.aGenerer);
}

class Bail {
  final int? id;
  final String? reference;
  final int appartementId;
  final String? appartementReference;
  final int? immeubleId;
  final String? immeubleNom;
  final int locataireId;
  final String? locataireNom;
  final String? locataireTelephone;

  /// Habitation ou professionnel ; nul à la création : déduit du logement.
  final UsageBail? usage;
  final DateTime dateDebut;
  final DateTime? dateFin;

  /// Nul à la création : le backend reprend alors le loyer du logement.
  final double? loyerMensuel;
  final double? charges;
  final double? montantMensuel;
  final double? depotGarantie;

  /// Mois de loyer exigés en caution ; le dépôt de garantie en découle.
  final int? moisCaution;

  /// Mois de loyer réglés d'avance à la signature : ils ne sont pas facturés.
  final int? moisAvance;
  final double? montantAvance;

  /// Premier mois pour lequel un loyer est émis (premier jour du mois).
  final DateTime? premierMoisFacture;

  /// Date d'enregistrement du bail : base du calcul du premier mois facturé.
  final DateTime? creeLe;
  final int? jourEcheance;

  /// Loyers recouvrés par une autre entité : l'application n'en émet aucun.
  final bool externe;

  /// Entité chargée du recouvrement d'un bail externe ; facultatif.
  final String? gestionnaireExterne;
  final StatutBail statut;
  final DateTime? dateResiliation;
  final String? motifResiliation;
  final String? resiliePar;

  final StatutContrat statutContrat;
  final DateTime? contratGenereLe;
  final String? contratSigneNom;
  final String? contratSigneType;
  final int? contratSigneTaille;
  final DateTime? contratSigneLe;
  final String? contratSignePar;

  const Bail({
    this.id,
    this.reference,
    required this.appartementId,
    this.appartementReference,
    this.immeubleId,
    this.immeubleNom,
    required this.locataireId,
    this.locataireNom,
    this.locataireTelephone,
    this.usage,
    required this.dateDebut,
    this.dateFin,
    this.loyerMensuel,
    this.charges,
    this.montantMensuel,
    this.depotGarantie,
    this.moisCaution,
    this.moisAvance,
    this.montantAvance,
    this.premierMoisFacture,
    this.creeLe,
    this.jourEcheance,
    this.externe = false,
    this.gestionnaireExterne,
    this.statut = StatutBail.actif,
    this.dateResiliation,
    this.motifResiliation,
    this.resiliePar,
    this.statutContrat = StatutContrat.aGenerer,
    this.contratGenereLe,
    this.contratSigneNom,
    this.contratSigneType,
    this.contratSigneTaille,
    this.contratSigneLe,
    this.contratSignePar,
  });

  bool get estActif => statut == StatutBail.actif;

  /// Délai, après l'enregistrement, pendant lequel le bail peut passer externe
  /// ou redevenir interne. Même règle que le backend.
  static const delaiChangementRecouvrementJours = 45;

  /// Dernier jour où le recouvrement peut encore changer.
  DateTime get limiteChangementRecouvrement {
    final c = creeLe ?? DateTime.now();
    return DateTime(c.year, c.month, c.day + delaiChangementRecouvrementJours);
  }

  bool recouvrementModifiable([DateTime? aujourdhui]) {
    final a = aujourdhui ?? DateTime.now();
    return !DateTime(a.year, a.month, a.day).isAfter(limiteChangementRecouvrement);
  }

  /// Premier mois facturé = le plus tardif du mois suivant l'enregistrement et
  /// du mois de début + les mois d'avance. Même règle que le backend.
  static DateTime calculerPremierMoisFacture(DateTime dateDebut, int moisAvance, DateTime creation) {
    final apresCreation = DateTime(creation.year, creation.month + 1);
    final apresAvance = DateTime(dateDebut.year, dateDebut.month + moisAvance);
    return apresCreation.isAfter(apresAvance) ? apresCreation : apresAvance;
  }

  String get logement => [appartementReference, immeubleNom]
      .where((s) => s != null && s.isNotEmpty)
      .join(' — ');
}
