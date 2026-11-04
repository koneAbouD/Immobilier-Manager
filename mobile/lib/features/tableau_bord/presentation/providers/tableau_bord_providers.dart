import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
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
