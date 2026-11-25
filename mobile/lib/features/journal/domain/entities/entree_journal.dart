import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Nature de la donnée tracée.
enum TypeEntiteJournal {
  bien('BIEN', 'Bien', 'Biens', Icons.apartment_rounded),
  local('LOCAL', 'Local', 'Locaux', Icons.door_front_door_outlined),
  locataire('LOCATAIRE', 'Locataire', 'Locataires', Icons.person_outline_rounded),
  travaux('TRAVAUX', 'Travaux', 'Travaux', Icons.build_outlined);

  final String code;
  final String libelle;
  final String pluriel;
  final IconData icone;

  const TypeEntiteJournal(this.code, this.libelle, this.pluriel, this.icone);

  static TypeEntiteJournal fromCode(String? code) =>
      values.firstWhere((t) => t.code == code, orElse: () => TypeEntiteJournal.bien);

  Color get couleur => switch (this) {
        TypeEntiteJournal.bien => AppColors.primaryDark,
        TypeEntiteJournal.local => AppColors.info,
        TypeEntiteJournal.locataire => AppColors.ambre,
        TypeEntiteJournal.travaux => AppColors.success,
      };
}

/// Opération tracée.
enum ActionJournal {
  modification('MODIFICATION', 'Modifié', 'Modifications', 'modifié', Icons.edit_outlined),
  suppression('SUPPRESSION', 'Supprimé', 'Suppressions', 'supprimé', Icons.delete_outline_rounded);

  final String code;
  final String libelle;
  final String pluriel;
  final String participe;
  final IconData icone;

  const ActionJournal(this.code, this.libelle, this.pluriel, this.participe, this.icone);

  static ActionJournal fromCode(String? code) =>
      values.firstWhere((a) => a.code == code, orElse: () => ActionJournal.modification);

  Color get couleur => this == ActionJournal.suppression ? AppColors.error : AppColors.warning;
}

/// Un champ touché : valeur avant et après (après nul pour une suppression).
class Changement {
  final String champ;
  final String? avant;
  final String? apres;

  const Changement(this.champ, this.avant, this.apres);

  factory Changement.fromJson(Map<String, dynamic> j) =>
      Changement(j['champ'] as String? ?? '', j['avant'] as String?, j['apres'] as String?);
}

/// Trace d'une modification ou d'une suppression.
class EntreeJournal {
  final int id;
  final DateTime date;
  final ActionJournal action;
  final TypeEntiteJournal type;
  final int? entiteId;
  final String libelle;
  final String? contexte;
  final String auteur;
  final List<Changement> changements;

  const EntreeJournal({
    required this.id,
    required this.date,
    required this.action,
    required this.type,
    this.entiteId,
    required this.libelle,
    this.contexte,
    required this.auteur,
    required this.changements,
  });

  bool get estSuppression => action == ActionJournal.suppression;

  factory EntreeJournal.fromJson(Map<String, dynamic> j) => EntreeJournal(
        id: (j['id'] as num).toInt(),
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        action: ActionJournal.fromCode(j['action'] as String?),
        type: TypeEntiteJournal.fromCode(j['typeEntite'] as String?),
        entiteId: (j['entiteId'] as num?)?.toInt(),
        libelle: (j['libelle'] as String?)?.trim().isNotEmpty == true ? j['libelle'] as String : 'Sans nom',
        contexte: j['contexte'] as String?,
        auteur: (j['auteurNom'] as String?)?.trim().isNotEmpty == true ? j['auteurNom'] as String : 'Inconnu',
        changements: ((j['changements'] as List?) ?? const [])
            .map((c) => Changement.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
