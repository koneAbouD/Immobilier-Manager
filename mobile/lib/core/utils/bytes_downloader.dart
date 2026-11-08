/// Enregistrement d'un fichier binaire (PDF…) : dans le navigateur sur le web,
/// dans « Téléchargements » sur Android, dans le dossier temporaire ailleurs.
library;

export 'bytes_downloader_stub.dart' if (dart.library.html) 'bytes_downloader_web.dart';
