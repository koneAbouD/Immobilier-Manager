import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../appartement/domain/entities/appartement.dart';

/// Où en est un locataire vis-à-vis de ses loyers.
enum SituationLocataire {
  enRetard('EN_RETARD', 'En retard'),
  aJour('A_JOUR', 'À jour'),
  sansBail('SANS_BAIL', 'Sans bail');

  final String code;
  final String libelle;
  const SituationLocataire(this.code, this.libelle);

  Color get couleur => switch (this) {
        enRetard => AppColors.error,
        aJour => AppColors.positive,
        sansBail => AppColors.grey500,
      };

  static SituationLocataire fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => SituationLocataire.sansBail);
}

/// Locataire vu depuis la liste : identité, logement en cours, état des loyers.
class LocataireResume {
  final int id;
  final String nom;
  final String prenom;
  final String nomComplet;
  final String telephone;
  final String? profession;
  final SituationLocataire situation;
  final int nombreBauxActifs;
  final String? logementReference;
  final String? immeubleNom;
  final TypeLogement? typeLogement;
  final double montantEnRetard;
  final int joursRetard;
  final int contratsASigner;

  const LocataireResume({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    required this.telephone,
    this.profession,
    required this.situation,
    required this.nombreBauxActifs,
    this.logementReference,
    this.immeubleNom,
    this.typeLogement,
    required this.montantEnRetard,
    required this.joursRetard,
    required this.contratsASigner,
  });

  String get initiales =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

  /// « A01 · Résidence Les Palmiers », « + 1 autre » si plusieurs baux.
  String get logement {
    if (logementReference == null) return 'Aucun bail en cours';
    final base = [logementReference, immeubleNom].whereType<String>().join(' · ');
    return nombreBauxActifs > 1 ? '$base  +${nombreBauxActifs - 1}' : base;
  }
}

/// Nombre de locataires par situation, pour les filtres.
class ComptesSituations {
  final int total;
  final int enRetard;
  final int aJour;
  final int sansBail;

  const ComptesSituations({
    required this.total,
    required this.enRetard,
    required this.aJour,
    required this.sansBail,
  });

  int pour(SituationLocataire? s) => switch (s) {
        null => total,
        SituationLocataire.enRetard => enRetard,
        SituationLocataire.aJour => aJour,
        SituationLocataire.sansBail => sansBail,
      };
}
