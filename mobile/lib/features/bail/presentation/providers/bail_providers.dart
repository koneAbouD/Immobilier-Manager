import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/bail_remote_datasource.dart';
import '../../data/repositories_impl/bail_repository_impl.dart';
import '../../domain/entities/bail.dart';
import '../../domain/repositories/bail_repository.dart';

final bailRepositoryProvider = Provider<BailRepository>(
  (ref) => BailRepositoryImpl(BailRemoteDatasource(ref.watch(apiClientProvider))),
);

final bailDetailProvider = FutureProvider.autoDispose.family<Bail, int>((ref, id) async {
  final result = await ref.watch(bailRepositoryProvider).getById(id);
  return result.fold((f) => throw f.message, (b) => b);
});
