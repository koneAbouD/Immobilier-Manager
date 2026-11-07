import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/immeuble_remote_datasource.dart';
import '../../data/repositories_impl/immeuble_repository_impl.dart';
import '../../domain/entities/immeuble.dart';
import '../../domain/entities/photo_bien.dart';
import '../../domain/repositories/immeuble_repository.dart';

final immeubleRepositoryProvider = Provider<ImmeubleRepository>(
  (ref) => ImmeubleRepositoryImpl(ImmeubleRemoteDatasource(ref.watch(apiClientProvider))),
);

/// Liste complète pour les sélecteurs ; à invalider après création/suppression.
final immeublesListeProvider = FutureProvider.autoDispose<List<Immeuble>>((ref) async {
  final result = await ref.watch(immeubleRepositoryProvider).getAll();
  return result.fold((f) => throw f.message, (l) => l);
});

final immeubleDetailProvider =
    FutureProvider.autoDispose.family<Immeuble, int>((ref, id) async {
  final result = await ref.watch(immeubleRepositoryProvider).getById(id);
  return result.fold((f) => throw f.message, (i) => i);
});

/// Photos du bien, de la plus ancienne à la plus récente.
final photosBienProvider = FutureProvider.autoDispose.family<List<PhotoBien>, int>((ref, id) async {
  final result = await ref.watch(immeubleRepositoryProvider).getPhotos(id);
  return result.fold((f) => throw f.message, (l) => l);
});

/// Contenu d'une photo, gardé en mémoire tant que l'application tourne : une
/// photo ne change jamais (on la remplace en la supprimant).
final photoOctetsProvider = FutureProvider.family<Uint8List, ({int bien, int photo})>((ref, cle) async {
  final result = await ref.watch(immeubleRepositoryProvider).telechargerPhoto(cle.bien, cle.photo);
  return result.fold((f) => throw f.message, (b) => b);
});
