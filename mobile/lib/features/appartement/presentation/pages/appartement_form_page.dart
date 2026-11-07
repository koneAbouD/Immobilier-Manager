import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/appartement.dart';
import '../providers/appartement_providers.dart';

/// Création d'un logement dans un immeuble, ou modification d'un logement.
class AppartementFormPage extends ConsumerStatefulWidget {
  final int immeubleId;
  final Appartement? appartement;

  const AppartementFormPage({super.key, required this.immeubleId, this.appartement});

  @override
  ConsumerState<AppartementFormPage> createState() => _AppartementFormPageState();
}

class _AppartementFormPageState extends ConsumerState<AppartementFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final a = widget.appartement;
  late final _reference = TextEditingController(text: a?.reference);
  late final _etage = TextEditingController(text: a?.etage?.toString());
  late final _superficie = TextEditingController(text: a?.superficie?.toStringAsFixed(0));
  late final _pieces = TextEditingController(text: a?.nombrePieces?.toString());
  late final _loyer = TextEditingController(text: a?.loyerMensuel.toStringAsFixed(0));
  late final _charges = TextEditingController(text: a?.charges.toStringAsFixed(0));
  late final _description = TextEditingController(text: a?.description);
  late TypeLogement? _type = a?.type;
  late StatutAppartement _statut = a?.statut ?? StatutAppartement.libre;
  bool _envoi = false;

  bool get _edition => a != null;

  /// OCCUPE est piloté par les baux : il n'est jamais proposé à la saisie.
  bool get _statutModifiable => a?.statut != StatutAppartement.occupe;

  @override
  void dispose() {
    for (final c in [_reference, _etage, _superficie, _pieces, _loyer, _charges, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final saisie = Appartement(
      immeubleId: widget.immeubleId,
      reference: _reference.text.trim(),
      etage: int.tryParse(_etage.text),
      type: _type!,
      superficie: parseMontantSaisi(_superficie.text),
      nombrePieces: int.tryParse(_pieces.text),
      loyerMensuel: parseMontantSaisi(_loyer.text)!,
      charges: parseMontantSaisi(_charges.text) ?? 0,
      statut: _statut,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
    );
    final repo = ref.read(appartementRepositoryProvider);
    final result = _edition ? await repo.update(a!.id!, saisie) : await repo.create(saisie);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, _edition ? 'Logement modifié.' : 'Logement créé.');
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: _edition ? 'Modifier le logement' : 'Nouveau logement'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            GroupeChamps(titre: 'Local', icone: Icons.home_work_outlined, children: [
              ChampChoix<TypeLogement>(
                label: 'Type',
                valeur: _type,
                options: TypeLogement.saisissables,
                libelle: (t) => t.libelle,
                obligatoire: true,
                onChanged: (t) => setState(() => _type = t),
              ),
              kGapChamps,
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ChampTexte(controller: _reference, label: 'Référence', hint: 'Ex. A01', obligatoire: true)),
                const SizedBox(width: 12),
                Expanded(child: ChampEntier(controller: _etage, label: 'Étage', aide: '0 = rez-de-chaussée')),
              ]),
              kGapChamps,
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ChampEntier(controller: _superficie, label: 'Superficie (m²)')),
                const SizedBox(width: 12),
                Expanded(child: ChampEntier(controller: _pieces, label: 'Pièces')),
              ]),
            ]),
            GroupeChamps(titre: 'Loyer', icone: Icons.payments_outlined, couleur: AppColors.positive, children: [
              ChampMontant(
                  controller: _loyer, label: 'Loyer mensuel', obligatoire: true, strictementPositif: true),
              kGapChamps,
              ChampMontant(controller: _charges, label: 'Charges mensuelles'),
            ]),
            GroupeChamps(titre: 'Statut et description', icone: Icons.tune_rounded, couleur: AppColors.info, children: [
              if (_statutModifiable)
                ChampChoix<StatutAppartement>(
                  label: 'Statut',
                  valeur: _statut,
                  options: const [StatutAppartement.libre, StatutAppartement.enTravaux],
                  libelle: (s) => s.libelle,
                  onChanged: (s) => setState(() => _statut = s ?? StatutAppartement.libre),
                )
              else
                Text('Ce logement est occupé : son statut suit le bail en cours.',
                    style: TextStyle(fontSize: 13, color: AppColors.label)),
              kGapChamps,
              ChampTexte(controller: _description, label: 'Description', hint: 'Équipements, état…', maxLines: 3),
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
