import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/guard.dart';
import '../../domain/entities/tableau_bord.dart';
import '../../domain/repositories/tableau_bord_repository.dart';
import '../datasources/tableau_bord_remote_datasource.dart';

class TableauBordRepositoryImpl implements TableauBordRepository {
  final TableauBordRemoteDatasource _ds;
  const TableauBordRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, TableauBord>> get({DateTime? periode}) =>
      guard(() => _ds.get(periode: periode));
}
