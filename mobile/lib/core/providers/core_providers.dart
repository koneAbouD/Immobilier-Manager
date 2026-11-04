import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/secure_storage.dart';

final secureStorageProvider =
    Provider<SecureStorage>((_) => const SecureStorage());

/// Client unique de l'application : un seul point de refresh et de fin de session.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(secureStorageProvider)),
);
