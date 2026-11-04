import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/loyer_remote_datasource.dart';
import '../../data/repositories_impl/loyer_repository_impl.dart';
import '../../domain/repositories/loyer_repository.dart';

final loyerRepositoryProvider = Provider<LoyerRepository>(
  (ref) => LoyerRepositoryImpl(LoyerRemoteDatasource(ref.watch(apiClientProvider))),
);
