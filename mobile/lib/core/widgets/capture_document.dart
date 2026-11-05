import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../theme/app_colors.dart';
import 'app_header.dart';
import 'feedback.dart';
import 'form_fields.dart';


/// Envoie le PDF assemblé ; renvoie un message d'erreur, ou null si c'est bon.
typedef EnvoiDocument = Future<String?> Function(Uint8List pdf, String nomFichier);

/// Numérise un document papier (contrat signé, pièce d'identité…) : une photo
/// par page, réunies en un seul PDF, ou un PDF déjà numérisé. Le PDF est
/// transmis à [envoyer] ; l'écran se ferme en renvoyant vrai une fois accepté.
class CaptureDocumentPage extends StatefulWidget {
  /// Titre de l'en-tête (« Pièce d'identité »).
  final String titre;

  /// Rappel de ce qui est numérisé (« Fatou Bamba · CNI »).
  final String? sousTitre;

  /// Nom du PDF assemblé à partir des photos.
  final String nomFichier;

  /// Libellé du bouton d'envoi (« Archiver la pièce d'identité »).
  final String libelleEnvoi;

  /// Message affiché une fois le document accepté.
  final String messageSucces;

  /// Consigne de prise de vue (« Recto puis verso… »).
  final String aidePhoto;
  final EnvoiDocument envoyer;

  const CaptureDocumentPage({
    super.key,
    required this.titre,
    required this.nomFichier,
    required this.libelleEnvoi,
    required this.messageSucces,
    required this.envoyer,
    this.sousTitre,
    this.aidePhoto = 'Une photo par page, réunies en un seul PDF',
  });

  @override
  State<CaptureDocumentPage> createState() => _CaptureDocumentPageState();
}

class _CaptureDocumentPageState extends State<CaptureDocumentPage> {
  final _picker = ImagePicker();
  final List<Uint8List> _pages = [];
  bool _envoi = false;

  Future<void> _photographier() async {
    final photo = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 70, maxWidth: 2000, maxHeight: 2000);
    if (photo == null) return;
    final octets = await photo.readAsBytes();
    setState(() => _pages.add(octets));
  }

  Future<void> _choisirPhotos() async {
    final photos = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 2000, maxHeight: 2000);
    if (photos.isEmpty) return;
    final octets = await Future.wait(photos.map((p) => p.readAsBytes()));
    setState(() => _pages.addAll(octets));
  }

  Future<void> _choisirPdf() async {
    final resultat = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: const ['pdf'], withData: true);
    final fichier = resultat?.files.single;
    if (fichier?.bytes == null) return;
    await _envoyer(fichier!.bytes!, fichier.name);
  }

  /// Une page A4 par photo, l'image ajustée à la page.
  Future<Uint8List> _assembler() async {
    final doc = pw.Document(title: widget.titre);
    for (final page in _pages) {
      final image = pw.MemoryImage(page);
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ));
    }
    return doc.save();
  }

  Future<void> _envoyerPhotos() async {
    setState(() => _envoi = true);
    final pdf = await _assembler();
    await _envoyer(pdf, widget.nomFichier);
  }

  Future<void> _envoyer(Uint8List pdf, String nom) async {
    setState(() => _envoi = true);
    final erreur = await widget.envoyer(pdf, nom);
    if (!mounted) return;
    setState(() => _envoi = false);
    if (erreur != null) {
      showError(context, erreur);
      return;
    }
    showSuccess(context, widget.messageSucces);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: widget.titre),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (widget.sousTitre != null) ...[
            Text(widget.sousTitre!, style: TextStyle(fontSize: 13, color: AppColors.label)),
            const SizedBox(height: 14),
          ],
          if (_pages.isEmpty) ...[
            _GrandeAction(
              icone: Icons.photo_camera_outlined,
              titre: 'Prendre en photo',
              detail: widget.aidePhoto,
              onTap: _envoi ? null : _photographier,
            ),
            const SizedBox(height: 10),
            _GrandeAction(
              icone: Icons.photo_library_outlined,
              titre: 'Choisir des photos',
              detail: 'Depuis la galerie du téléphone',
              onTap: _envoi ? null : _choisirPhotos,
            ),
            const SizedBox(height: 10),
            _GrandeAction(
              icone: Icons.picture_as_pdf_outlined,
              titre: 'Choisir un PDF',
              detail: 'Document déjà numérisé',
              onTap: _envoi ? null : _choisirPdf,
            ),
            if (_envoi) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ] else ...[
            Text('${_pages.length} page(s)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
              children: [
                for (final (i, page) in _pages.indexed)
                  Stack(children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(page, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton.filled(
                        tooltip: 'Retirer la page',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.6)),
                        onPressed: _envoi ? null : () => setState(() => _pages.removeAt(i)),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ),
                  ]),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: BoutonSecondaire(
                  label: 'Photo',
                  icon: Icons.add_a_photo_outlined,
                  onPressed: _envoi ? null : _photographier,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BoutonSecondaire(
                  label: 'Galerie',
                  icon: Icons.add_photo_alternate_outlined,
                  onPressed: _envoi ? null : _choisirPhotos,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            BoutonPrincipal(
              label: widget.libelleEnvoi,
              icon: Icons.cloud_upload_outlined,
              loading: _envoi,
              onPressed: _envoyerPhotos,
            ),
          ],
        ],
      ),
    );
  }
}

class _GrandeAction extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String detail;
  final VoidCallback? onTap;

  const _GrandeAction({required this.icone, required this.titre, required this.detail, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: Icon(icone, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titre,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(fontSize: 12, color: AppColors.label)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
          ]),
        ),
      ),
    );
  }
}

// ── Aperçus ─────────────────────────────────────────────────────────────────

/// Aperçu d'un PDF avec partage (WhatsApp, e-mail…) et impression.
class ApercuPdfPage extends StatelessWidget {
  final String titre;
  final String nomFichier;
  final Uint8List pdf;

  const ApercuPdfPage({super.key, required this.titre, required this.nomFichier, required this.pdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: titre),
      body: PdfPreview(
        build: (_) async => pdf,
        pdfFileName: nomFichier,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: true,
        allowPrinting: true,
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class ApercuImagePage extends StatelessWidget {
  final String titre;
  final Uint8List image;

  const ApercuImagePage({super.key, required this.titre, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: titre),
      body: InteractiveViewer(child: Center(child: Image.memory(image))),
    );
  }
}
