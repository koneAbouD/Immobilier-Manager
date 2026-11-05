import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/page_result.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../loyer/domain/entities/echeance.dart';
import '../../../loyer/domain/entities/paiement.dart';
import '../../../loyer/presentation/providers/loyer_providers.dart';
import '../../data/datasources/tableau_bord_remote_datasource.dart';
import '../../data/repositories_impl/tableau_bord_repository_impl.dart';
import '../../domain/entities/tableau_bord.dart';
import '../../domain/repositories/tableau_bord_repository.dart';

final tableauBordRepositoryProvider = Provider<TableauBordRepository>(
  (ref) => TableauBordRepositoryImpl(TableauBordRemoteDatasource(ref.watch(apiClientProvider))),
);

final tableauBordProvider = FutureProvider.autoDispose<TableauBord>((ref) async {
  final result = await ref.watch(tableauBordRepositoryProvider).get();
  return result.fold((f) => throw f.message, (t) => t);
});

// ── Listes de l'accueil, centrées sur les locataires et leurs loyers ───────

/// Nombre de lignes montrées par liste de l'accueil ; le reste est dans
/// l'onglet Loyers.
const accueilTailleListe = 5;

/// Loyers en retard, du mois le plus récent au plus ancien.
final accueilRetardsProvider = FutureProvider.autoDispose<PageResult<Echeance>>((ref) async {
  final result = await ref
      .watch(loyerRepositoryProvider)
      .getEcheances(size: accueilTailleListe, enRetard: true);
  return result.fold((f) => throw f.message, (p) => p);
});

/// Loyers du mois encore à encaisser et pas encore en retard, par date
/// d'échéance.
final accueilAEncaisserProvider = FutureProvider.autoDispose<List<Echeance>>((ref) async {
  final result = await ref.watch(loyerRepositoryProvider).getEcheances(
      size: accueilTailleListe * 4, periode: DateTime.now(), aEncaisser: true);
  return result.fold(
    (f) => throw f.message,
    (p) => p.content.where((e) => !e.enRetard).take(accueilTailleListe).toList(),
  );
});

/// Derniers paiements reçus, du plus récent au plus ancien.
final accueilPaiementsProvider = FutureProvider.autoDispose<List<Paiement>>((ref) async {
  final result =
      await ref.watch(loyerRepositoryProvider).getPaiements(size: accueilTailleListe);
  return result.fold((f) => throw f.message, (p) => p.content);
});
