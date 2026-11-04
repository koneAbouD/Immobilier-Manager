import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/maintenance.dart';
import '../providers/maintenance_providers.dart';
import 'maintenance_form_page.dart';

class MaintenanceDetailPage extends ConsumerStatefulWidget {
  final int maintenanceId;

  const MaintenanceDetailPage({super.key, required this.maintenanceId});

  @override
  ConsumerState<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends ConsumerState<MaintenanceDetailPage> {
  void _rafraichir() => ref.invalidate(maintenanceDetailProvider(widget.maintenanceId));

  Future<void> _action(Future<Either<Failure, Object?>> Function() appel, String succes) async {
    final result = await appel();
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, succes);
      _rafraichir();
    });
  }

  Future<void> _terminer(Maintenance m) async {
    final cout = TextEditingController(text: m.coutEstime?.toStringAsFixed(0));
    final ok = await dialogueSaisie(context,
        titre: 'Terminer l\'intervention',
        contenu: ChampMontant(controller: cout, label: 'Coût réel'),
        action: 'Terminer');
    final montant = parseMontantSaisi(cout.text);
    cout.dispose();
    if (!ok) return;
    await _action(
        () => ref.read(maintenanceRepositoryProvider).terminer(m.id!, coutReel: montant),
        'Intervention terminée.');
  }

  Future<void> _annuler(Maintenance m) async {
    final motif = await demanderMotif(context, titre: 'Annuler l\'intervention', action: 'Annuler l\'intervention');
    if (motif == null) return;
    await _action(() => ref.read(maintenanceRepositoryProvider).annuler(m.id!, motif), 'Intervention annulée.');
  }

  Future<void> _supprimer(Maintenance m) async {
    final ok = await confirmer(context,
        titre: 'Supprimer ce signalement ?',
        message: 'Le signalement sera définitivement supprimé.',
        action: 'Supprimer',
        destructive: true);
    if (!ok || !mounted) return;
    final result = await ref.read(maintenanceRepositoryProvider).delete(m.id!);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Signalement supprimé.');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(maintenanceDetailProvider(widget.maintenanceId));
    return async.when(
      loading: () => const Scaffold(
          appBar: AppHeader(title: ''),
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: const AppHeader(title: ''),
          body: ErrorView(message: '$e', onRetry: _rafraichir)),
      data: (m) => Scaffold(
        appBar: AppHeader(
          title: 'Intervention',
          action: ActionsDetail(
            onModifier: m.statut.estOuverte
                ? () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => MaintenanceFormPage(maintenance: m)));
                    _rafraichir();
                  }
                : null,
            onSupprimer: m.statut == StatutMaintenance.signalee ? () => _supprimer(m) : null,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            DetailHeroCard(
              icon: m.categorie.icone,
              iconColor: m.priorite.couleur,
              titre: m.titre,
              sousTitre: m.localisation,
              statutLabel: m.statut.libelle,
              statutColor: m.statut.couleur,
            ),
            DetailInfoCard(children: [
              DetailInfoRow(Icons.category_outlined, 'Catégorie', m.categorie.libelle),
              DetailInfoRow(Icons.flag_outlined, 'Priorité', m.priorite.libelle,
                  valueColor: m.priorite == PrioriteMaintenance.urgente ? AppColors.error : null),
              DetailInfoRow(Icons.notes_rounded, 'Description', m.description),
              DetailInfoRow(Icons.event_note_outlined, 'Signalée le', formatDate(m.dateSignalement)),
              DetailInfoRow(Icons.event_outlined, 'Prévue le',
                  m.datePrevue == null ? null : formatDate(m.datePrevue)),
              DetailInfoRow(Icons.event_available_outlined, 'Réalisée le',
                  m.dateRealisation == null ? null : formatDate(m.dateRealisation)),
              DetailInfoRow(Icons.engineering_outlined, 'Prestataire', m.prestataire),
              DetailInfoRow(Icons.request_quote_outlined, 'Coût estimé',
                  m.coutEstime == null ? null : formatMontant(m.coutEstime)),
              DetailInfoRow(Icons.payments_outlined, 'Coût réel',
                  m.coutReel == null ? null : formatMontant(m.coutReel)),
            ]),
            if (m.statut == StatutMaintenance.annulee)
              DetailInfoCard(titre: 'Annulation', icon: Icons.cancel_outlined, children: [
                DetailInfoRow(Icons.notes_rounded, 'Motif', m.motifAnnulation),
                DetailInfoRow(Icons.person_outline, 'Annulée par', m.annulePar),
              ]),
            if (m.statut.estOuverte) ...[
              const SizedBox(height: 4),
              BoutonPrincipal(
                label: 'Terminer',
                icon: Icons.check_rounded,
                onPressed: () => _terminer(m),
              ),
              if (m.statut != StatutMaintenance.enCours) ...[
                const SizedBox(height: 10),
                BoutonSecondaire(
                  label: 'Démarrer',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => _action(
                      () => ref.read(maintenanceRepositoryProvider).demarrer(m.id!),
                      'Intervention démarrée.'),
                ),
              ],
              const SizedBox(height: 10),
              BoutonSecondaire(
                label: 'Annuler l\'intervention',
                icon: Icons.cancel_outlined,
                destructive: true,
                onPressed: () => _annuler(m),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
