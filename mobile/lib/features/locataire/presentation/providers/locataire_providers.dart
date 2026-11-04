import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/locataire_remote_datasource.dart';
import '../../data/repositories_impl/locataire_repository_impl.dart';
import '../../domain/entities/locataire.dart';
import '../../domain/repositories/locataire_repository.dart';

final locataireRepositoryProvider = Provider<LocataireRepository>(
  (ref) => LocataireRepositoryImpl(LocataireRemoteDatasource(ref.watch(apiClientProvider))),
);

final locataireDetailProvider =
    FutureProvider.autoDispose.family<Locataire, int>((ref, id) async {
  final result = await ref.watch(locataireRepositoryProvider).getById(id);
  return result.fold((f) => throw f.message, (l) => l);
});
