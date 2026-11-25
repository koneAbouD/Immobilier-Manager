import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/redemarrage.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';

final secureStorageProvider =
    Provider<SecureStorage>((_) => const SecureStorage());

/// Client unique de l'application : un seul point de refresh et de fin de session.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(storage);
  ref.onDispose(client.arreterRenouvellement);
  // Organisation devenue inaccessible (membre retiré…) : on l'oublie et on
  // repasse par le choix d'organisation, sur un conteneur neuf.
  var enCours = false;
  client.onOrganisationInaccessible = () async {
    if (enCours) return;
    enCours = true;
    await storage.clearOrganisationId();
    await Redemarrage.lancer();
  };
  return client;
});
