import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum CategorieMaintenance {
  plomberie('PLOMBERIE', 'Plomberie', Icons.plumbing),
  electricite('ELECTRICITE', 'Électricité', Icons.electrical_services),
  peinture('PEINTURE', 'Peinture', Icons.format_paint),
  menuiserie('MENUISERIE', 'Menuiserie', Icons.carpenter),
  climatisation('CLIMATISATION', 'Climatisation', Icons.ac_unit),
  serrurerie('SERRURERIE', 'Serrurerie', Icons.key),
  maconnerie('MACONNERIE', 'Maçonnerie', Icons.foundation),
  nettoyage('NETTOYAGE', 'Nettoyage', Icons.cleaning_services),
  autre('AUTRE', 'Autre', Icons.build);

  final String code;
  final String libelle;
  final IconData icone;
  const CategorieMaintenance(this.code, this.libelle, this.icone);

  static CategorieMaintenance fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => CategorieMaintenance.autre);
}

enum PrioriteMaintenance {
  basse('BASSE', 'Basse'),
  normale('NORMALE', 'Normale'),
  haute('HAUTE', 'Haute'),
  urgente('URGENTE', 'Urgente');

  final String code;
  final String libelle;
  const PrioriteMaintenance(this.code, this.libelle);

  /// Teinte du statut, lue dans la charte : elle suit le thème clair/sombre.
  Color get couleur => switch (this) {
        basse => AppColors.hint,
        normale => AppColors.info,
        haute => AppColors.warning,
        urgente => AppColors.error,
      };

  static PrioriteMaintenance fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => PrioriteMaintenance.normale);
}

enum StatutMaintenance {
  signalee('SIGNALEE', 'Signalée'),
  planifiee('PLANIFIEE', 'Planifiée'),
  enCours('EN_COURS', 'En cours'),
  terminee('TERMINEE', 'Terminée'),
  annulee('ANNULEE', 'Annulée');

  final String code;
  final String libelle;
  const StatutMaintenance(this.code, this.libelle);

  /// Teinte du statut, lue dans la charte : elle suit le thème clair/sombre.
  Color get couleur => switch (this) {
        signalee => AppColors.ambre,
        planifiee => AppColors.info,
        enCours => AppColors.warning,
        terminee => AppColors.positive,
        annulee => AppColors.hint,
      };

  bool get estOuverte => this == signalee || this == planifiee || this == enCours;

  static StatutMaintenance fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => StatutMaintenance.signalee);
}

class Maintenance {
  final int? id;
  final int? immeubleId;
  final String? immeubleNom;
  final int? appartementId;
  final String? appartementReference;
  final String titre;
  final String? description;
  final CategorieMaintenance categorie;
  final PrioriteMaintenance priorite;
  final StatutMaintenance statut;
  final DateTime? dateSignalement;
  final DateTime? datePrevue;
  final DateTime? dateRealisation;
  final String? prestataire;
  final double? coutEstime;
  final double? coutReel;
  final String? motifAnnulation;
  final String? annulePar;

  const Maintenance({
    this.id,
    this.immeubleId,
    this.immeubleNom,
    this.appartementId,
    this.appartementReference,
    required this.titre,
    this.description,
    required this.categorie,
    this.priorite = PrioriteMaintenance.normale,
    this.statut = StatutMaintenance.signalee,
    this.dateSignalement,
    this.datePrevue,
    this.dateRealisation,
    this.prestataire,
    this.coutEstime,
    this.coutReel,
    this.motifAnnulation,
    this.annulePar,
  });

  /// « A01 — Résidence Les Palmiers » ou « Parties communes — … ».
  String get localisation =>
      '${appartementReference ?? 'Parties communes'} — ${immeubleNom ?? ''}';
}
