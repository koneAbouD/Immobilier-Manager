import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../loyer/presentation/widgets/echeances_liste.dart';
import '../../domain/entities/bail.dart';
import '../providers/bail_providers.dart';

class BailDetailPage extends ConsumerStatefulWidget {
  final int bailId;

  const BailDetailPage({super.key, required this.bailId});

  @override
  ConsumerState<BailDetailPage> createState() => _BailDetailPageState();
}

class _BailDetailPageState extends ConsumerState<BailDetailPage> {
  int _version = 0;

  void _rafraichir() {
    ref.invalidate(bailDetailProvider(widget.bailId));
    setState(() => _version++);
  }

  Future<void> _resilier(Bail bail) async {
    final date = await showDatePicker(
      context: context,
      helpText: 'Date d\'effet de la résiliation',
      initialDate: DateTime.now().isBefore(bail.dateDebut) ? bail.dateDebut : DateTime.now(),
      firstDate: bail.dateDebut,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final motif = await demanderMotif(context,
        titre: 'Résilier le bail ${bail.reference}', libelle: 'Motif de résiliation', action: 'Résilier');
    if (motif == null || !mounted) return;
    final result =
        await ref.read(bailRepositoryProvider).resilier(bail.id!, date: date, motif: motif);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Bail résilié : le logement est de nouveau libre.');
      _rafraichir();
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bailDetailProvider(widget.bailId));
    return async.when(
      loading: () => const Scaffold(
          appBar: AppHeader(title: ''),
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: const AppHeader(title: ''),
          body: ErrorView(message: '$e', onRetry: _rafraichir)),
      data: (b) => Scaffold(
        appBar: AppHeader(title: b.reference ?? 'Bail'),
        body: RefreshIndicator(
          onRefresh: () async => _rafraichir(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              DetailHeroCard(
                icon: Icons.description_outlined,
                titre: b.locataireNom ?? '',
                sousTitre: b.logement,
                statutLabel: b.statut.libelle,
                statutColor: b.statut.couleur,
              ),
              DetailInfoCard(titre: 'Conditions', icon: Icons.handshake_outlined, children: [
                DetailInfoRow(Icons.phone_outlined, 'Téléphone', b.locataireTelephone),
                DetailInfoRow(Icons.event_outlined, 'Début', formatDate(b.dateDebut)),
                DetailInfoRow(Icons.event_busy_outlined, 'Fin prévue',
                    b.dateFin == null ? 'Indéterminée' : formatDate(b.dateFin)),
                DetailInfoRow(Icons.today_outlined, 'Échéance', 'Le ${b.jourEcheance} de chaque mois'),
              ]),
              DetailInfoCard(titre: 'Montants', icon: Icons.payments_outlined, children: [
                DetailInfoRow(Icons.payments_outlined, 'Loyer', formatMontant(b.loyerMensuel)),
                DetailInfoRow(Icons.receipt_outlined, 'Charges', formatMontant(b.charges)),
                DetailInfoRow(Icons.summarize_outlined, 'Total mensuel', formatMontant(b.montantMensuel),
                    valueColor: AppColors.primaryDark),
                DetailInfoRow(Icons.savings_outlined, 'Dépôt de garantie', formatMontant(b.depotGarantie)),
              ]),
              if (!b.estActif)
                DetailInfoCard(titre: 'Résiliation', icon: Icons.logout_rounded, children: [
                  DetailInfoRow(Icons.event_outlined, 'Résilié le', formatDate(b.dateResiliation)),
                  DetailInfoRow(Icons.notes_rounded, 'Motif', b.motifResiliation),
                  DetailInfoRow(Icons.person_outline, 'Par', b.resiliePar),
                ]),
              if (b.estActif) ...[
                BoutonSecondaire(
                  label: 'Résilier le bail',
                  icon: Icons.logout_rounded,
                  destructive: true,
                  onPressed: () => _resilier(b),
                ),
                const SizedBox(height: 12),
              ],
              const SectionTitre('Loyers'),
              EcheancesListe(key: ValueKey(_version), bailId: b.id!),
            ],
          ),
        ),
      ),
    );
  }
}
