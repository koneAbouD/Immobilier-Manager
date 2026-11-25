import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Rôle dans une organisation, du plus au moins étendu : chacun inclut les
/// droits de ceux qui le suivent.
enum RoleMembre {
  proprietaire('PROPRIETAIRE', 'Propriétaire', 'Abonnement, équipe et réglages', Icons.workspace_premium_rounded),
  admin('ADMIN', 'Administrateur', 'Équipe et réglages de l\'organisation', Icons.admin_panel_settings_outlined),
  gestionnaire('GESTIONNAIRE', 'Gestionnaire', 'Biens, baux, loyers et travaux', Icons.manage_accounts_outlined),
  lecteur('LECTEUR', 'Lecteur', 'Consultation seule', Icons.visibility_outlined);

  final String code;
  final String libelle;
  final String description;
  final IconData icone;

  const RoleMembre(this.code, this.libelle, this.description, this.icone);

  static RoleMembre fromCode(String? code) =>
      values.firstWhere((r) => r.code == code, orElse: () => RoleMembre.lecteur);

  /// Vrai si ce rôle donne au moins les droits de [autre].
  bool inclut(RoleMembre autre) => index <= autre.index;

  bool get peutEcrire => inclut(RoleMembre.gestionnaire);
  bool get estAdmin => inclut(RoleMembre.admin);

  /// Vrai si ce rôle autorise [action] (hors état de l'abonnement).
  bool peut(ActionMetier action) => inclut(action.roleMinimal);

  Color get couleur => switch (this) {
        RoleMembre.proprietaire => AppColors.ambre,
        RoleMembre.admin => AppColors.primary,
        RoleMembre.gestionnaire => AppColors.info,
        RoleMembre.lecteur => AppColors.label,
      };
}

/// Matrice des actions sur les données métier : le rôle minimal de chacune.
/// Miroir des règles de `SecurityConfig` côté backend, qui fait foi (et que
/// `MatriceDroitsTest` fige) : toute modification se fait des deux côtés.
enum ActionMetier {
  /// Créer et modifier biens, locaux, locataires, baux, loyers, travaux.
  ecrire(RoleMembre.gestionnaire),

  /// Supprimer un locataire saisi par erreur (jamais loué).
  supprimerLocataire(RoleMembre.gestionnaire),

  /// Supprimer un local : touche au patrimoine, ne s'annule pas.
  supprimerLocal(RoleMembre.admin),

  /// Supprimer un bien, avec ses photos.
  supprimerBien(RoleMembre.admin),

  /// Consulter le journal des modifications et suppressions (supervision).
  consulterJournal(RoleMembre.admin);

  final RoleMembre roleMinimal;
  const ActionMetier(this.roleMinimal);
}

/// Ce que l'abonnement permet aujourd'hui.
enum AccesOrganisation {
  complet('COMPLET'),
  lectureSeule('LECTURE_SEULE'),
  bloque('BLOQUE');

  final String code;
  const AccesOrganisation(this.code);

  static AccesOrganisation fromCode(String? code) =>
      values.firstWhere((a) => a.code == code, orElse: () => AccesOrganisation.complet);
}

enum StatutAbonnement {
  essai('ESSAI', 'Essai gratuit'),
  actif('ACTIF', 'Actif'),
  suspendu('SUSPENDU', 'Suspendu'),
  resilie('RESILIE', 'Résilié');

  final String code;
  final String libelle;
  const StatutAbonnement(this.code, this.libelle);

  static StatutAbonnement fromCode(String? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => StatutAbonnement.actif);

  Color get couleur => switch (this) {
        StatutAbonnement.essai => AppColors.info,
        StatutAbonnement.actif => AppColors.success,
        StatutAbonnement.suspendu => AppColors.warning,
        StatutAbonnement.resilie => AppColors.error,
      };
}

/// Formule d'abonnement. Limite nulle = illimitée ; tarif nul = sur devis.
class Plan {
  final String code;
  final String libelle;
  final int? lotsMax;
  final int? membresMax;
  final int? tarifMensuel;

  const Plan({required this.code, required this.libelle, this.lotsMax, this.membresMax, this.tarifMensuel});

  bool get gratuit => tarifMensuel == 0;
  bool get surDevis => tarifMensuel == null;
}

/// Adhésion de l'utilisateur connecté à une organisation.
class Adhesion {
  final int organisationId;
  final String organisation;
  final RoleMembre role;
  final StatutAbonnement statut;
  final AccesOrganisation acces;

  const Adhesion({
    required this.organisationId,
    required this.organisation,
    required this.role,
    required this.statut,
    required this.acces,
  });
}

/// L'utilisateur connecté et ses organisations.
class Profil {
  final int id;

  /// Facultatif : un compte peut n'avoir que son numéro de téléphone.
  final String? email;
  final String? telephone;
  final String? prenom;
  final String? nom;
  final String nomComplet;
  final bool superAdmin;
  final List<Adhesion> organisations;

  const Profil({
    required this.id,
    required this.nomComplet,
    required this.superAdmin,
    required this.organisations,
    this.email,
    this.telephone,
    this.prenom,
    this.nom,
  });

  /// Identifiant de connexion : le téléphone, à défaut l'e-mail.
  String? get identifiant => telephone ?? email;

  Adhesion? adhesion(int? organisationId) {
    for (final a in organisations) {
      if (a.organisationId == organisationId) return a;
    }
    return null;
  }
}

class Abonnement {
  final Plan plan;
  final StatutAbonnement statut;
  final AccesOrganisation acces;
  final String? motifRestriction;
  final DateTime? essaiFinLe;
  final DateTime? abonnementFinLe;
  final int? joursRestants;
  final int biens;
  final int lots;
  final int membres;

  const Abonnement({
    required this.plan,
    required this.statut,
    required this.acces,
    required this.biens,
    required this.lots,
    required this.membres,
    this.motifRestriction,
    this.essaiFinLe,
    this.abonnementFinLe,
    this.joursRestants,
  });

  /// Fin de l'essai ou de la période payée proche : à signaler.
  bool get echeanceProche => joursRestants != null && joursRestants! <= 7;
}

/// Organisation courante : identité du bailleur et abonnement.
class OrganisationCourante {
  final int id;
  final String nom;
  final String? representant;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? ville;
  final String pays;
  final String devise;
  final bool logo;
  final Abonnement abonnement;
  final RoleMembre? monRole;

  const OrganisationCourante({
    required this.id,
    required this.nom,
    required this.pays,
    required this.devise,
    required this.logo,
    required this.abonnement,
    this.representant,
    this.email,
    this.telephone,
    this.adresse,
    this.ville,
    this.monRole,
  });
}

/// Membre de l'équipe de l'organisation courante.
class MembreEquipe {
  final int id;
  final int utilisateurId;
  final String? email;
  final String? telephone;
  final String? prenom;
  final String? nom;
  final RoleMembre role;
  final bool actif;
  final DateTime? ajouteLe;
  final DateTime? derniereConnexion;

  /// Renseigné une seule fois, à la création du compte.
  final String? motDePasseTemporaire;

  const MembreEquipe({
    required this.id,
    required this.utilisateurId,
    required this.role,
    required this.actif,
    this.email,
    this.telephone,
    this.prenom,
    this.nom,
    this.ajouteLe,
    this.derniereConnexion,
    this.motDePasseTemporaire,
  });

  /// Identifiant de connexion : l'e-mail pour un invité, le téléphone sinon.
  String get identifiant => email ?? telephone ?? '';

  String get nomComplet {
    final complet = '${prenom ?? ''} ${nom ?? ''}'.trim();
    return complet.isEmpty ? identifiant : complet;
  }

  String get initiales {
    final p = (prenom ?? '').trim();
    final n = (nom ?? '').trim();
    final i = '${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}'.toUpperCase();
    return i.isEmpty ? (identifiant.isEmpty ? '?' : identifiant[0].toUpperCase()) : i;
  }
}
