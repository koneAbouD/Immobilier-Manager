import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../domain/entities/photo_bien.dart';
import '../providers/immeuble_providers.dart';

/// Photos d'un bien sur sa fiche : vignettes défilantes, ajout depuis
/// l'appareil photo ou la galerie, ouverture en plein écran.
class GaleriePhotosBien extends ConsumerStatefulWidget {
  final int immeubleId;

  const GaleriePhotosBien({super.key, required this.immeubleId});

  @override
  ConsumerState<GaleriePhotosBien> createState() => _GaleriePhotosBienState();
}

class _GaleriePhotosBienState extends ConsumerState<GaleriePhotosBien> {
  final _picker = ImagePicker();
  bool _envoi = false;

  int get _id => widget.immeubleId;

  Future<void> _ajouter() async {
    final source = await afficherFeuille<ImageSource>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const EnteteFeuille(icone: Icons.add_photo_alternate_outlined, titre: 'Ajouter des photos'),
          const SizedBox(height: 16),
          _ChoixSource(
            icone: Icons.photo_camera_outlined,
            titre: 'Prendre une photo',
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          const SizedBox(height: 10),
          _ChoixSource(
            icone: Icons.photo_library_outlined,
            titre: 'Choisir dans la galerie',
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    // Images réduites et recompressées : une photo de bien n'a pas besoin de
    // la pleine résolution de l'appareil.
    final List<XFile> fichiers = source == ImageSource.camera
        ? [?await _picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1800)]
        : await _picker.pickMultiImage(imageQuality: 75, maxWidth: 1800);
    if (fichiers.isEmpty || !mounted) return;

    setState(() => _envoi = true);
    final repo = ref.read(immeubleRepositoryProvider);
    var ajoutees = 0;
    String? erreur;
    for (final f in fichiers) {
      final type = f.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final result = await repo.ajouterPhoto(_id, contenu: await f.readAsBytes(), nomFichier: f.name, type: type);
      result.fold((e) => erreur ??= e.message, (_) => ajoutees++);
      if (erreur != null) break;
    }
    if (!mounted) return;
    setState(() => _envoi = false);
    ref.invalidate(photosBienProvider(_id));
    if (erreur != null) {
      showError(context, ajoutees == 0 ? erreur! : '$ajoutees photo(s) ajoutée(s). $erreur');
    } else {
      showSuccess(context, ajoutees == 1 ? 'Photo ajoutée.' : '$ajoutees photos ajoutées.');
    }
  }

  void _ouvrir(List<PhotoBien> photos, int index) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VisionneusePhotosBien(immeubleId: _id, photos: photos, index: index)),
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(photosBienProvider(_id));
    final photos = async.valueOrNull ?? const <PhotoBien>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitre(
        photos.isEmpty ? 'Photos' : 'Photos (${photos.length})',
        action: _envoi
            ? const Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : BoutonTexte(label: 'Ajouter', icon: Icons.add_a_photo_outlined, onTap: _ajouter),
      ),
      async.when(
        loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => TextButton(
          onPressed: () => ref.invalidate(photosBienProvider(_id)),
          child: Text('$e — Réessayer'),
        ),
        data: (photos) => photos.isEmpty
            ? _AucunePhoto(onTap: _envoi ? null : _ajouter)
            : SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _Vignette(
                    immeubleId: _id,
                    photo: photos[i],
                    onTap: () => _ouvrir(photos, i),
                  ),
                ),
              ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

class _AucunePhoto extends StatelessWidget {
  final VoidCallback? onTap;

  const _AucunePhoto({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.primaryDark),
            const SizedBox(height: 6),
            Text('Ajouter des photos du bien',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
            const SizedBox(height: 2),
            Text('Façade, intérieur, terrain…', style: TextStyle(fontSize: 11.5, color: AppColors.label)),
          ]),
        ),
      ),
    );
  }
}

class _Vignette extends ConsumerWidget {
  final int immeubleId;
  final PhotoBien photo;
  final VoidCallback onTap;

  const _Vignette({required this.immeubleId, required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final octets = ref.watch(photoOctetsProvider((bien: immeubleId, photo: photo.id)));
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          color: AppColors.grey100,
          child: octets.when(
            data: (b) => Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true),
            loading: () => const Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, _) => Icon(Icons.broken_image_outlined, color: AppColors.grey400),
          ),
        ),
      ),
    );
  }
}

class _ChoixSource extends StatelessWidget {
  final IconData icone;
  final String titre;
  final VoidCallback onTap;

  const _ChoixSource({required this.icone, required this.titre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: Icon(icone, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(titre,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark)),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
          ]),
        ),
      ),
    );
  }
}

/// Photos du bien en plein écran : balayage d'une photo à l'autre, zoom au
/// pincement, suppression de la photo affichée.
class VisionneusePhotosBien extends ConsumerStatefulWidget {
  final int immeubleId;
  final List<PhotoBien> photos;
  final int index;

  const VisionneusePhotosBien({super.key, required this.immeubleId, required this.photos, required this.index});

  @override
  ConsumerState<VisionneusePhotosBien> createState() => _VisionneusePhotosBienState();
}

class _VisionneusePhotosBienState extends ConsumerState<VisionneusePhotosBien> {
  late final _controller = PageController(initialPage: widget.index);
  late final List<PhotoBien> _photos = [...widget.photos];
  late int _index = widget.index;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _supprimer() async {
    final photo = _photos[_index];
    final ok = await confirmer(context,
        titre: 'Supprimer cette photo ?',
        message: 'Elle sera retirée du bien définitivement.',
        action: 'Supprimer',
        destructive: true);
    if (!ok || !mounted) return;
    final result = await ref.read(immeubleRepositoryProvider).supprimerPhoto(widget.immeubleId, photo.id);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      ref.invalidate(photosBienProvider(widget.immeubleId));
      showSuccess(context, 'Photo supprimée.');
      if (_photos.length == 1) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _photos.removeAt(_index);
        if (_index >= _photos.length) _index = _photos.length - 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photos[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppHeader(
        title: '${_index + 1} / ${_photos.length}',
        action: AppHeaderAction(icon: Icons.delete_outline_rounded, onTap: _supprimer),
      ),
      body: Column(children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: _photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final octets = ref.watch(photoOctetsProvider((bien: widget.immeubleId, photo: _photos[i].id)));
              return octets.when(
                data: (b) => InteractiveViewer(maxScale: 5, child: Center(child: Image.memory(b))),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white54)),
                error: (e, _) => Center(
                    child: Text('$e', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center)),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text(
              [
                if (photo.ajouteeLe != null) 'Ajoutée le ${formatDate(photo.ajouteeLe)}',
                if (photo.ajouteePar != null) 'par ${photo.ajouteePar}',
              ].join(' '),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ),
      ]),
    );
  }
}
