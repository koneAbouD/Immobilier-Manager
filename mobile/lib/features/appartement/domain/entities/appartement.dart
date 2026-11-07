import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Nature du local loué ; la taille d'un appartement se lit dans ses pièces.
enum TypeLogement {
  appartement('APPARTEMENT', 'Appartement', Icons.door_front_door_outlined),
  magasin('MAGASIN', 'Magasin', Icons.storefront_outlined),
  bureau('BUREAU', 'Bureau', Icons.business_center_outlined),
  entrepot('ENTREPOT', 'Entrepôt', Icons.warehouse_outlined),

  /// Le terrain lui-même, loué nu : local créé avec un bien de type terrain,
  /// jamais saisi à la main.
  terrain('TERRAIN', 'Terrain', Icons.landscape_outlined);

  /// Types proposés à la saisie d'un local.
  static List<TypeLogement> get saisissables => values.where((t) => t != terrain).toList();

  final String code;
  final String libelle;
  final IconData icone;
  const TypeLogement(this.code, this.libelle, this.icone);

  static TypeLogement fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => TypeLogement.appartement);
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
