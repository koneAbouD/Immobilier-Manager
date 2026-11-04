import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/appartement_remote_datasource.dart';
import '../../data/repositories_impl/appartement_repository_impl.dart';
import '../../domain/entities/appartement.dart';
import '../../domain/repositories/appartement_repository.dart';

final appartementRepositoryProvider = Provider<AppartementRepository>(
  (ref) => AppartementRepositoryImpl(AppartementRemoteDatasource(ref.watch(apiClientProvider))),
);

final appartementDetailProvider =
    FutureProvider.autoDispose.family<Appartement, int>((ref, id) async {
  final result = await ref.watch(appartementRepositoryProvider).getById(id);
  return result.fold((f) => throw f.message, (a) => a);
});
