import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum StatutEcheance {
  aPayer('A_PAYER', 'À payer'),
  partiel('PARTIEL', 'Partiel'),
  payee('PAYEE', 'Payée'),
  annulee('ANNULEE', 'Annulée');

  final String code;
  final String libelle;
  const StatutEcheance(this.code, this.libelle);

  /// Teinte du statut, lue dans la charte : elle suit le thème clair/sombre.
  Color get couleur => switch (this) {
        aPayer => AppColors.warning,
        partiel => AppColors.info,
        payee => AppColors.positive,
        annulee => AppColors.hint,
      };

  static StatutEcheance fromCode(String? code) =>
      values.firstWhere((v) => v.code == code, orElse: () => StatutEcheance.aPayer);
}

/// Loyer d'un mois pour un bail.
class Echeance {
  final int id;
  final int bailId;
  final String? bailReference;
  final int locataireId;
  final String locataireNom;
  final String? locataireTelephone;
  final String? appartementReference;
  final String? immeubleNom;
  final DateTime periode;
  final DateTime dateEcheance;
  final double montantDu;
  final double montantPaye;
  final double resteDu;
  final StatutEcheance statut;
  final bool enRetard;

  const Echeance({
    required this.id,
    required this.bailId,
    this.bailReference,
    required this.locataireId,
    required this.locataireNom,
    this.locataireTelephone,
    this.appartementReference,
    this.immeubleNom,
    required this.periode,
    required this.dateEcheance,
    required this.montantDu,
    required this.montantPaye,
    required this.resteDu,
    required this.statut,
    required this.enRetard,
  });

  bool get encaissable => statut == StatutEcheance.aPayer || statut == StatutEcheance.partiel;

  String get logement => [appartementReference, immeubleNom]
      .where((s) => s != null && s.isNotEmpty)
      .join(' — ');
}
