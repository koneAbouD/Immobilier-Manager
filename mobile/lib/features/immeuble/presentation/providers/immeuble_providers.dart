import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/immeuble_remote_datasource.dart';
import '../../data/repositories_impl/immeuble_repository_impl.dart';
import '../../domain/entities/immeuble.dart';
import '../../domain/repositories/immeuble_repository.dart';

final immeubleRepositoryProvider = Provider<ImmeubleRepository>(
  (ref) => ImmeubleRepositoryImpl(ImmeubleRemoteDatasource(ref.watch(apiClientProvider))),
);

/// Liste complète pour les sélecteurs ; à invalider après création/suppression.
final immeublesListeProvider = FutureProvider.autoDispose<List<Immeuble>>((ref) async {
  final result = await ref.watch(immeubleRepositoryProvider).getAll();
  return result.fold((f) => throw f.message, (l) => l);
});

final immeubleDetailProvider =
    FutureProvider.autoDispose.family<Immeuble, int>((ref, id) async {
  final result = await ref.watch(immeubleRepositoryProvider).getById(id);
  return result.fold((f) => throw f.message, (i) => i);
});
