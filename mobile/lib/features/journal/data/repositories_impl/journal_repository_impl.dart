import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/entities/entree_journal.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_remote_datasource.dart';

class JournalRepositoryImpl implements JournalRepository {
  final JournalRemoteDatasource _ds;
  const JournalRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, PageResult<EntreeJournal>>> getPage({
    int page = 0,
    int size = 20,
    TypeEntiteJournal? type,
    ActionJournal? action,
    String? recherche,
  }) =>
      guard(() => _ds.getPage(page: page, size: size, type: type, action: action, recherche: recherche));
}
