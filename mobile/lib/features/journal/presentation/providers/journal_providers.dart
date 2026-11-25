import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/journal_remote_datasource.dart';
import '../../data/repositories_impl/journal_repository_impl.dart';
import '../../domain/repositories/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => JournalRepositoryImpl(JournalRemoteDatasource(ref.watch(apiClientProvider))),
);
