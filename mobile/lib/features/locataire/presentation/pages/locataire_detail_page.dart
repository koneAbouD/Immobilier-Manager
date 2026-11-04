import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../bail/presentation/pages/bail_form_page.dart';
import '../../../bail/presentation/widgets/baux_liste.dart';
import '../../domain/entities/locataire.dart';
import '../providers/locataire_providers.dart';
import 'locataire_form_page.dart';

class LocataireDetailPage extends ConsumerStatefulWidget {
  final int locataireId;

  const LocataireDetailPage({super.key, required this.locataireId});

  @override
  ConsumerState<LocataireDetailPage> createState() => _LocataireDetailPageState();
}

class _LocataireDetailPageState extends ConsumerState<LocataireDetailPage> {
  int _version = 0;

  void _rafraichir() {
    ref.invalidate(locataireDetailProvider(widget.locataireId));
    setState(() => _version++);
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _rafraichir();
  }

  Future<void> _supprimer(Locataire l) async {
    final ok = await confirmer(context,
        titre: 'Supprimer le locataire ?',
        message: '${l.nomComplet} sera définitivement supprimé.',
        action: 'Supprimer',
        destructive: true);
    if (!ok || !mounted) return;
    final result = await ref.read(locataireRepositoryProvider).delete(l.id!);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Locataire supprimé.');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(locataireDetailProvider(widget.locataireId));
    return async.when(
      loading: () => const Scaffold(
          appBar: AppHeader(title: ''),
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: const AppHeader(title: ''),
          body: ErrorView(message: '$e', onRetry: _rafraichir)),
      data: (l) => Scaffold(
        appBar: AppHeader(
          title: 'Locataire',
          action: ActionsDetail(
            extra: AppHeaderAction(
              icon: Icons.call_outlined,
              onTap: () => launchUrl(Uri(scheme: 'tel', path: l.telephone)),
            ),
            onModifier: () => _ouvrir(LocataireFormPage(locataire: l)),
            onSupprimer: () => _supprimer(l),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _rafraichir(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _HeroLocataire(locataire: l),
              DetailInfoCard(titre: 'Coordonnées', icon: Icons.contact_page_outlined, children: [
                DetailInfoRow(Icons.phone_outlined, 'Téléphone', l.telephone),
                DetailInfoRow(Icons.alternate_email_rounded, 'E-mail', l.email),
                DetailInfoRow(Icons.place_outlined, 'Adresse', l.adresse),
                DetailInfoRow(Icons.work_outline_rounded, 'Profession', l.profession),
                DetailInfoRow(Icons.cake_outlined, 'Né(e) le',
                    l.dateNaissance == null ? null : formatDate(l.dateNaissance)),
                DetailInfoRow(Icons.badge_outlined, 'Pièce',
                    [l.typePiece?.libelle, l.numeroPiece].whereType<String>().join(' n° ')),
                DetailInfoRow(Icons.emergency_outlined, 'Urgence',
                    [l.contactUrgenceNom, l.contactUrgenceTelephone].whereType<String>().join(' · ')),
              ]),
              BoutonPrincipal(
                label: 'Signer un bail',
                icon: Icons.draw_outlined,
                onPressed: () => _ouvrir(BailFormPage(locataireInitial: l)),
              ),
              const SizedBox(height: 12),
              const SectionTitre('Baux'),
              BauxListe(key: ValueKey(_version), locataireId: l.id, onChange: _rafraichir),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête du locataire : initiales dans une pastille ronde, nom et téléphone.
class _HeroLocataire extends StatelessWidget {
  final Locataire locataire;

  const _HeroLocataire({required this.locataire});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
          child: Text(locataire.initiales,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(locataire.nomComplet,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(locataire.telephone,
                style: TextStyle(fontSize: 12.5, color: AppColors.label)),
          ]),
        ),
      ]),
    );
  }
}
