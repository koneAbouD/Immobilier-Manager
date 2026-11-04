import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/tableau_bord.dart';

abstract interface class TableauBordRepository {
  Future<Either<Failure, TableauBord>> get({DateTime? periode});
}
