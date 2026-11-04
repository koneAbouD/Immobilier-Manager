import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/maintenance_remote_datasource.dart';
import '../../data/repositories_impl/maintenance_repository_impl.dart';
import '../../domain/entities/maintenance.dart';
import '../../domain/repositories/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepositoryImpl(MaintenanceRemoteDatasource(ref.watch(apiClientProvider))),
);

final maintenanceDetailProvider =
    FutureProvider.autoDispose.family<Maintenance, int>((ref, id) async {
  final result = await ref.watch(maintenanceRepositoryProvider).getById(id);
  return result.fold((f) => throw f.message, (m) => m);
});
