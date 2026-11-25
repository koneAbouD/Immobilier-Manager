import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../entities/entree_journal.dart';

abstract class JournalRepository {
  Future<Either<Failure, PageResult<EntreeJournal>>> getPage({
    int page = 0,
    int size = 20,
    TypeEntiteJournal? type,
    ActionJournal? action,
    String? recherche,
  });
}
