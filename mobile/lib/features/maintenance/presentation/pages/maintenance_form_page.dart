import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/selection_page.dart';
import '../../../appartement/domain/entities/appartement.dart';
import '../../../appartement/presentation/providers/appartement_providers.dart';
import '../../../immeuble/domain/entities/immeuble.dart';
import '../../../immeuble/presentation/providers/immeuble_providers.dart';
import '../../domain/entities/maintenance.dart';
import '../providers/maintenance_providers.dart';

/// Signalement d'une intervention, ou modification d'une intervention ouverte.
class MaintenanceFormPage extends ConsumerStatefulWidget {
  final Maintenance? maintenance;
  final int? immeubleIdInitial;
  final Appartement? appartementInitial;

  const MaintenanceFormPage({
    super.key,
    this.maintenance,
    this.immeubleIdInitial,
    this.appartementInitial,
  });

  @override
  ConsumerState<MaintenanceFormPage> createState() => _MaintenanceFormPageState();
}

class _MaintenanceFormPageState extends ConsumerState<MaintenanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final m = widget.maintenance;
  late final _titre = TextEditingController(text: m?.titre);
  late final _description = TextEditingController(text: m?.description);
  late final _prestataire = TextEditingController(text: m?.prestataire);
  late final _cout = TextEditingController(text: m?.coutEstime?.toStringAsFixed(0));
  late int? _immeubleId = m?.immeubleId ?? widget.immeubleIdInitial;
  late int? _appartementId = m?.appartementId ?? widget.appartementInitial?.id;
  late String? _appartementLibelle = m?.appartementReference ?? widget.appartementInitial?.reference;
  late CategorieMaintenance? _categorie = m?.categorie;
  late PrioriteMaintenance _priorite = m?.priorite ?? PrioriteMaintenance.normale;
  late DateTime? _datePrevue = m?.datePrevue;
  bool _envoi = false;

  bool get _edition => m != null;

  @override
  void dispose() {
    for (final c in [_titre, _description, _prestataire, _cout]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<Appartement?> _choisirAppartement() {
    final repo = ref.read(appartementRepositoryProvider);
    return Navigator.push<Appartement>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionPage<Appartement>(
          titre: 'Logement concerné',
          fetcherPour: (r) => (page, size) =>
              repo.getPage(page: page, size: size, immeubleId: _immeubleId, recherche: r),
          titreItem: (a) => a.reference,
          sousTitreItem: (a) => '${a.type.libelle} · ${a.statut.libelle}',
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final saisie = Maintenance(
      immeubleId: _immeubleId,
      appartementId: _appartementId,
      titre: _titre.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      categorie: _categorie!,
      priorite: _priorite,
      dateSignalement: m?.dateSignalement,
      datePrevue: _datePrevue,
      prestataire: _prestataire.text.trim().isEmpty ? null : _prestataire.text.trim(),
      coutEstime: parseMontantSaisi(_cout.text),
    );
    final repo = ref.read(maintenanceRepositoryProvider);
    final result = _edition ? await repo.update(m!.id!, saisie) : await repo.signaler(saisie);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, _edition ? 'Intervention modifiée.' : 'Intervention signalée.');
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final immeubles = ref.watch(immeublesListeProvider);
    return Scaffold(
      appBar: AppHeader(title: _edition ? 'Modifier l\'intervention' : 'Signaler une intervention'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            GroupeChamps(titre: 'Localisation', icone: Icons.place_outlined, children: [
              immeubles.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e', style: TextStyle(color: AppColors.error)),
                data: (liste) => ChampChoix<int>(
                  label: 'Bien',
                  valeur: _immeubleId,
                  obligatoire: true,
                  options: liste.map((i) => i.id!).toList(),
                  libelle: (id) => liste.firstWhere((i) => i.id == id, orElse: () => const Immeuble(nom: '?')).nom,
                  onChanged: (id) => setState(() {
                    if (id != _immeubleId) {
                      _appartementId = null;
                      _appartementLibelle = null;
                    }
                    _immeubleId = id;
                  }),
                ),
              ),
              kGapChamps,
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: ChampSelection<Appartement>(
                    key: ValueKey(_appartementLibelle),
                    label: 'Logement',
                    valeurAffichee: _appartementLibelle,
                    actif: _immeubleId != null,
                    ouvrir: _choisirAppartement,
                    onSelected: (a) => setState(() {
                      _appartementId = a.id;
                      _appartementLibelle = a.reference;
                    }),
                  ),
                ),
                if (_appartementId != null)
                  IconButton(
                    tooltip: 'Parties communes (aucun logement)',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _appartementId = null;
                      _appartementLibelle = null;
                    }),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text('Sans logement, l\'intervention concerne les parties communes.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.hint)),
              ),
            ]),
            GroupeChamps(titre: 'Intervention', icone: Icons.build_outlined, couleur: AppColors.warning, children: [
              ChampTexte(controller: _titre, label: 'Titre', hint: 'Ex. Fuite sous l\'évier', obligatoire: true),
              kGapChamps,
              ChampChoix<CategorieMaintenance>(
                label: 'Catégorie',
                valeur: _categorie,
                obligatoire: true,
                options: CategorieMaintenance.values,
                libelle: (c) => c.libelle,
                onChanged: (c) => setState(() => _categorie = c),
              ),
              kGapChamps,
              ChampChoix<PrioriteMaintenance>(
                label: 'Priorité',
                valeur: _priorite,
                options: PrioriteMaintenance.values,
                libelle: (p) => p.libelle,
                onChanged: (p) => setState(() => _priorite = p ?? PrioriteMaintenance.normale),
              ),
              kGapChamps,
              ChampTexte(controller: _description, label: 'Description', maxLines: 3),
            ]),
            GroupeChamps(titre: 'Planification', icone: Icons.event_outlined, couleur: AppColors.info, children: [
              ChampDate(
                label: 'Date d\'intervention prévue',
                valeur: _datePrevue,
                onChanged: (d) => setState(() => _datePrevue = d),
              ),
              kGapChamps,
              ChampTexte(controller: _prestataire, label: 'Prestataire'),
              kGapChamps,
              ChampMontant(controller: _cout, label: 'Coût estimé'),
            ]),
            const SizedBox(height: 8),
            BoutonPrincipal(
              label: 'Enregistrer',
              loading: _envoi,
              onPressed: _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}
