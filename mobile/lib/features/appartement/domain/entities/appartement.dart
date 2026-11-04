import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum TypeLogement {
  studio('STUDIO', 'Studio'),
  chambreSalon('CHAMBRE_SALON', 'Chambre-salon'),
  t2('T2', 'T2'),
  t3('T3', 'T3'),
  t4('T4', 'T4'),
  t5Plus('T5_PLUS', 'T5 et plus'),
  duplex('DUPLEX', 'Duplex'),
  villa('VILLA', 'Villa'),
  magasin('MAGASIN', 'Magasin'),
  bureau('BUREAU', 'Bureau');

  final String code;
  final String libelle;
  const TypeLogement(this.code, this.libelle);

  static TypeLogement fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => TypeLogement.t2);
}

enum StatutAppartement {
  libre('LIBRE', 'Libre'),
  occupe('OCCUPE', 'Occupé'),
  enTravaux('EN_TRAVAUX', 'En travaux');

  final String code;
  final String libelle;
  const StatutAppartement(this.code, this.libelle);

  /// Teinte du statut, lue dans la charte : elle suit le thème clair/sombre.
  Color get couleur => switch (this) {
        libre => AppColors.positive,
        occupe => AppColors.info,
        enTravaux => AppColors.warning,
      };

  static StatutAppartement fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => StatutAppartement.libre);
}

class Appartement {
  final int? id;
  final int immeubleId;
  final String? immeubleNom;
  final String reference;
  final int? etage;
  final TypeLogement type;
  final double? superficie;
  final int? nombrePieces;
  final double loyerMensuel;
  final double charges;
  final StatutAppartement statut;
  final String? description;

  const Appartement({
    this.id,
    required this.immeubleId,
    this.immeubleNom,
    required this.reference,
    this.etage,
    required this.type,
    this.superficie,
    this.nombrePieces,
    required this.loyerMensuel,
    this.charges = 0,
    this.statut = StatutAppartement.libre,
    this.description,
  });

  double get montantMensuel => loyerMensuel + charges;

  /// « A01 — Résidence Les Palmiers ».
  String get libelleComplet =>
      immeubleNom == null ? reference : '$reference — $immeubleNom';

  String get libelleEtage => switch (etage) {
        null => '—',
        0 => 'Rez-de-chaussée',
        1 => '1er étage',
        final n => '${n}e étage',
      };
}
