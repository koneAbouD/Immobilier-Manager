import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../bail/presentation/pages/bail_form_page.dart';
import '../../../bail/presentation/widgets/baux_liste.dart';
import '../../../maintenance/presentation/pages/maintenance_form_page.dart';
import '../../domain/entities/appartement.dart';
import '../providers/appartement_providers.dart';
import 'appartement_form_page.dart';

class AppartementDetailPage extends ConsumerStatefulWidget {
  final int appartementId;

  const AppartementDetailPage({super.key, required this.appartementId});

  @override
  ConsumerState<AppartementDetailPage> createState() => _AppartementDetailPageState();
}

class _AppartementDetailPageState extends ConsumerState<AppartementDetailPage> {
  int _version = 0;

  void _rafraichir() {
    ref.invalidate(appartementDetailProvider(widget.appartementId));
    setState(() => _version++);
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _rafraichir();
  }

  Future<void> _supprimer(Appartement a) async {
    final ok = await confirmer(context,
        titre: 'Supprimer le local ?',
        message: 'Le local ${a.reference} sera définitivement supprimé.',
        action: 'Supprimer',
        destructive: true);
    if (!ok || !mounted) return;
    final result = await ref.read(appartementRepositoryProvider).delete(a.id!);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Local supprimé.');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appartementDetailProvider(widget.appartementId));
    return async.when(
      loading: () => const Scaffold(
          appBar: AppHeader(title: ''),
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: const AppHeader(title: ''),
          body: ErrorView(message: '$e', onRetry: _rafraichir)),
      data: (a) => Scaffold(
        appBar: AppHeader(
          title: 'Local',
          action: ActionsDetail(
            onModifier: () =>
                _ouvrir(AppartementFormPage(immeubleId: a.immeubleId, appartement: a)),
            onSupprimer: () => _supprimer(a),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _rafraichir(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              DetailHeroCard(
                icon: Icons.door_front_door_outlined,
                titre: '${a.reference} · ${a.type.libelle}',
                sousTitre: a.immeubleNom,
                statutLabel: a.statut.libelle,
                statutColor: a.statut.couleur,
              ),
              DetailInfoCard(children: [
                DetailInfoRow(Icons.layers_outlined, 'Étage', a.libelleEtage),
                DetailInfoRow(Icons.square_foot_outlined, 'Superficie',
                    a.superficie == null ? null : '${a.superficie!.toStringAsFixed(0)} m²'),
                DetailInfoRow(Icons.meeting_room_outlined, 'Pièces', a.nombrePieces?.toString()),
                DetailInfoRow(Icons.notes_rounded, 'Description', a.description),
              ]),
              Row(children: [
                if (a.statut == StatutAppartement.libre) ...[
                  Expanded(
                    child: BoutonPrincipal(
                      label: 'Signer un bail',
                      icon: Icons.draw_outlined,
                      onPressed: () => _ouvrir(BailFormPage(appartementInitial: a)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: BoutonSecondaire(
                    label: 'Signaler',
                    icon: Icons.build_outlined,
                    onPressed: () => _ouvrir(MaintenanceFormPage(
                        immeubleIdInitial: a.immeubleId, appartementInitial: a)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const SectionTitre('Baux'),
              BauxListe(key: ValueKey(_version), appartementId: a.id, onChange: _rafraichir),
            ],
          ),
        ),
      ),
    );
  }
}
