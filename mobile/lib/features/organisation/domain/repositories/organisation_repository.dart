import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/organisation.dart';

abstract interface class OrganisationRepository {
  Future<Either<Failure, Profil>> moi();

  Future<Either<Failure, void>> changerMotDePasse(String actuel, String nouveau);

  Future<Either<Failure, OrganisationCourante>> courante();

  Future<Either<Failure, OrganisationCourante>> modifier(Map<String, dynamic> identite);

  Future<Either<Failure, Uint8List>> logo();

  Future<Either<Failure, OrganisationCourante>> deposerLogo(Uint8List contenu, String nomFichier, String type);

  Future<Either<Failure, void>> supprimerLogo();

  Future<Either<Failure, List<MembreEquipe>>> membres();

  Future<Either<Failure, MembreEquipe>> ajouterMembre(
      {required String email, required String prenom, required String nom, required RoleMembre role});

  Future<Either<Failure, MembreEquipe>> modifierMembre(int id, {RoleMembre? role, bool? actif});

  Future<Either<Failure, void>> retirerMembre(int id);

  Future<Either<Failure, MembreEquipe>> transfererPropriete(int id);

  Future<Either<Failure, List<Plan>>> plans();

  Future<Either<Failure, PageResult<OrganisationCourante>>> organisationsPlateforme(
      {int page = 0, int size = 20, String? recherche});

  Future<Either<Failure, OrganisationCourante>> modifierAbonnement(int organisationId,
      {required String plan, required String statut, DateTime? essaiFinLe, DateTime? abonnementFinLe});
}
