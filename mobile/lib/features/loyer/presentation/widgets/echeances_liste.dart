import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/page_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/echeance.dart';
import '../providers/loyer_providers.dart';
import 'echeance_tile.dart';
import 'encaissement_sheet.dart';

/// Loyers d'un bail, intégrés à sa fiche (les 60 derniers mois suffisent).
class EcheancesListe extends ConsumerStatefulWidget {
  final int bailId;

  const EcheancesListe({super.key, required this.bailId});

  @override
  ConsumerState<EcheancesListe> createState() => _EcheancesListeState();
}

class _EcheancesListeState extends ConsumerState<EcheancesListe> {
  late Future<Either<Failure, PageResult<Echeance>>> _future = _charger();

  Future<Either<Failure, PageResult<Echeance>>> _charger() =>
      ref.read(loyerRepositoryProvider).getEcheances(bailId: widget.bailId, size: 60);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, PageResult<Echeance>>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
              padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        return snap.data!.fold(
          (f) => Text(f.message, style: TextStyle(color: AppColors.error)),
          (page) => page.content.isEmpty
              ? Text('Aucun loyer émis.', style: TextStyle(color: AppColors.grey500))
              : Column(
                  children: page.content
                      .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EcheanceTile(
                            echeance: e,
                            afficherLocataire: false,
                            onTap: () async {
                              if (await ouvrirEcheance(context, e)) {
                                setState(() => _future = _charger());
                              }
                            },
                          )))
                      .toList(),
                ),
        );
      },
    );
  }
}
