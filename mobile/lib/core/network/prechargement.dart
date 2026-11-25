import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../features/immeuble/presentation/providers/immeuble_providers.dart';
import '../../features/locataire/presentation/providers/locataire_providers.dart';
import '../../features/loyer/presentation/providers/loyer_providers.dart';
import '../../features/maintenance/presentation/providers/maintenance_providers.dart';
import '../../features/organisation/presentation/providers/organisation_providers.dart';
import '../../features/tableau_bord/presentation/providers/tableau_bord_providers.dart';
import '../error/failure.dart';
import '../pagination/paged_list_notifier.dart';
import 'api_client.dart';

/// Écrans lus d'avance, pour être servis hors connexion même si le
/// gestionnaire ne les a pas ouverts : l'accueil, les loyers du mois, les
/// biens, les locataires, les maintenances et l'organisation.
///
/// Chaque lecture est **celle de l'écran**, filtres par défaut compris : le
/// cache retrouve une réponse par son URL exacte. D'où les appels aux mêmes
/// repositories, avec les mêmes arguments, que les écrans à leur ouverture —
/// à tenir alignés si un écran change ses filtres par défaut.
///
/// Repris de VTC Manager (`prechargerEcransCles`).
Future<void> prechargerEcransCles(WidgetRef ref) async {
  final loyers = ref.read(loyerRepositoryProvider);
  final tableauBord = ref.read(tableauBordRepositoryProvider);
  final biens = ref.read(immeubleRepositoryProvider);
  final locataires = ref.read(locataireRepositoryProvider);
  final maintenances = ref.read(maintenanceRepositoryProvider);
  final organisation = ref.read(organisationRepositoryProvider);

  final maintenant = DateTime.now();
  final mois = DateTime(maintenant.year, maintenant.month);
  const taille = PagedListNotifier.pageSize;

  final lectures = <Future<Either<Failure, Object?>> Function()>[
    // Accueil (tableau_bord_providers.dart).
    () => tableauBord.get(),
    () => loyers.getEcheances(size: accueilTailleListe, enRetard: true),
    () => loyers.getEcheances(
        size: accueilTailleListe * 4, periode: maintenant, aEncaisser: true),
    () => loyers.getPaiements(size: accueilTailleListe),
    // Loyers : mois courant, filtre « Tous » (loyers_page.dart).
    () => tableauBord.get(periode: mois),
    () => loyers.getEcheances(page: 0, size: taille, periode: mois),
    // Biens (immeubles_page.dart) et liste des biens des formulaires.
    () => biens.getPage(page: 0, size: taille, recherche: ''),
    () => biens.getAll(),
    // Locataires, toutes situations (locataires_page.dart).
    () => locataires.getResumes(page: 0, size: taille, recherche: ''),
    () => locataires.getComptes(recherche: ''),
    // Maintenances, tous statuts (maintenances_page.dart).
    () => maintenances.getPage(page: 0, size: taille, recherche: ''),
    // Réglages › Mon organisation.
    () => organisation.courante(),
  ];

  await ApiClient.precharger(() async {
    // Une lecture à la fois : le réseau mobile reste disponible pour les
    // écrans. Serveur hors d'atteinte : inutile d'essayer les suivantes. Un
    // refus (droits, abonnement) ne concerne que sa lecture.
    for (final lecture in lectures) {
      final resultat = await lecture();
      if (resultat case Left(value: NetworkFailure())) return;
    }
  });
}
