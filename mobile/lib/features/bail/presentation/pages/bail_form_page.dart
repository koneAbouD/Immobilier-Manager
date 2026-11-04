import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/selection_page.dart';
import '../../../appartement/domain/entities/appartement.dart';
import '../../../appartement/presentation/providers/appartement_providers.dart';
import '../../../locataire/domain/entities/locataire.dart';
import '../../../locataire/presentation/providers/locataire_providers.dart';
import '../../domain/entities/bail.dart';
import '../providers/bail_providers.dart';

/// Signature d'un bail. Le logement (libre uniquement) et le locataire se
/// choisissent dans une liste ; loyer et charges sont repris du logement et
/// restent ajustables.
class BailFormPage extends ConsumerStatefulWidget {
  final Appartement? appartementInitial;
  final Locataire? locataireInitial;

  const BailFormPage({super.key, this.appartementInitial, this.locataireInitial});

  @override
  ConsumerState<BailFormPage> createState() => _BailFormPageState();
}

class _BailFormPageState extends ConsumerState<BailFormPage> {
  final _formKey = GlobalKey<FormState>();
  late Appartement? _appartement = widget.appartementInitial;
  late Locataire? _locataire = widget.locataireInitial;
  DateTime? _dateDebut = DateTime.now();
  DateTime? _dateFin;
  final _loyer = TextEditingController();
  final _charges = TextEditingController();
  final _depot = TextEditingController();
  final _jour = TextEditingController(text: '5');
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    if (_appartement != null) _reprendreConditions(_appartement!);
  }

  @override
  void dispose() {
    for (final c in [_loyer, _charges, _depot, _jour]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reprendreConditions(Appartement a) {
    _loyer.text = a.loyerMensuel.toStringAsFixed(0);
    _charges.text = a.charges.toStringAsFixed(0);
    // Usage courant : deux mois de loyer en caution.
    _depot.text = (a.loyerMensuel * 2).toStringAsFixed(0);
  }

  Future<Appartement?> _choisirAppartement() {
    final repo = ref.read(appartementRepositoryProvider);
    return Navigator.push<Appartement>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionPage<Appartement>(
          titre: 'Logement libre',
          hintRecherche: 'Référence, immeuble…',
          emptyMessage: 'Aucun logement libre.',
          fetcherPour: (r) => (page, size) => repo.getPage(
              page: page, size: size, statut: StatutAppartement.libre, recherche: r),
          titreItem: (a) => a.libelleComplet,
          sousTitreItem: (a) => '${a.type.libelle} · ${formatMontant(a.montantMensuel)}/mois',
        ),
      ),
    );
  }

  Future<Locataire?> _choisirLocataire() {
    final repo = ref.read(locataireRepositoryProvider);
    return Navigator.push<Locataire>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionPage<Locataire>(
          titre: 'Locataire',
          hintRecherche: 'Nom, téléphone…',
          fetcherPour: (r) => (page, size) => repo.getPage(page: page, size: size, recherche: r),
          titreItem: (l) => l.nomComplet,
          sousTitreItem: (l) => l.telephone,
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final bail = Bail(
      appartementId: _appartement!.id!,
      locataireId: _locataire!.id!,
      dateDebut: _dateDebut!,
      dateFin: _dateFin,
      loyerMensuel: parseMontantSaisi(_loyer.text),
      charges: parseMontantSaisi(_charges.text),
      depotGarantie: parseMontantSaisi(_depot.text),
      jourEcheance: int.tryParse(_jour.text),
    );
    final result = await ref.read(bailRepositoryProvider).create(bail);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (b) {
      showSuccess(context, 'Bail ${b.reference} signé. Les loyers dus ont été émis.');
      Navigator.pop(context, b);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: 'Nouveau bail'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            ChampSelection<Appartement>(
              label: 'Logement',
              valeurAffichee: _appartement?.libelleComplet,
              obligatoire: true,
              actif: widget.appartementInitial == null,
              ouvrir: _choisirAppartement,
              onSelected: (a) => setState(() {
                _appartement = a;
                _reprendreConditions(a);
              }),
            ),
            kGapChamps,
            ChampSelection<Locataire>(
              label: 'Locataire',
              valeurAffichee: _locataire?.nomComplet,
              obligatoire: true,
              actif: widget.locataireInitial == null,
              ouvrir: _choisirLocataire,
              onSelected: (l) => setState(() => _locataire = l),
            ),
            kGapChamps,
            Row(children: [
              Expanded(
                child: ChampDate(
                  label: 'Début',
                  valeur: _dateDebut,
                  obligatoire: true,
                  onChanged: (d) => setState(() => _dateDebut = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChampDate(
                  label: 'Fin (facultatif)',
                  valeur: _dateFin,
                  premiere: _dateDebut,
                  onChanged: (d) => setState(() => _dateFin = d),
                ),
              ),
            ]),
            kGapChamps,
            ChampMontant(
                controller: _loyer, label: 'Loyer mensuel', obligatoire: true, strictementPositif: true),
            kGapChamps,
            ChampMontant(controller: _charges, label: 'Charges mensuelles'),
            kGapChamps,
            ChampMontant(controller: _depot, label: 'Dépôt de garantie'),
            kGapChamps,
            TextFormField(
              controller: _jour,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jour d\'échéance du loyer *',
                helperText: 'Jour du mois où le loyer est exigible (1 à 28)',
              ),
              validator: (v) {
                final j = int.tryParse(v ?? '');
                return j == null || j < 1 || j > 28 ? 'Entre 1 et 28.' : null;
              },
            ),
            const SizedBox(height: 24),
            BoutonPrincipal(
              label: 'Signer le bail',
              loading: _envoi,
              onPressed: _enregistrer,
            ),
          ],
        ),
      ),
    );
  }
}
