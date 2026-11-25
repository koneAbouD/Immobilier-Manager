import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/locataire_remote_datasource.dart';
import '../../data/repositories_impl/locataire_repository_impl.dart';
import '../../domain/entities/locataire.dart';
import '../../domain/entities/locataire_resume.dart';
import '../../domain/repositories/locataire_repository.dart';

final locataireRepositoryProvider = Provider<LocataireRepository>(
  (ref) => LocataireRepositoryImpl(LocataireRemoteDatasource(ref.watch(apiClientProvider))),
);

final locataireDetailProvider =
    FutureProvider.autoDispose.family<Locataire, int>((ref, id) async {
  final result = await ref.watch(locataireRepositoryProvider).getById(id);
  return result.fold((f) => throw f.message, (l) => l);
});

/// Filtres de la liste des locataires qui pèsent sur les comptes par situation.
typedef FiltreLocataires = ({String recherche, int? immeubleId});

/// Répartition par situation des locataires répondant à la recherche et au bien choisi.
final comptesSituationsProvider =
    FutureProvider.autoDispose.family<ComptesSituations, FiltreLocataires>((ref, filtre) async {
  final result = await ref
      .watch(locataireRepositoryProvider)
      .getComptes(recherche: filtre.recherche, immeubleId: filtre.immeubleId);
  return result.fold((f) => throw f.message, (c) => c);
});
