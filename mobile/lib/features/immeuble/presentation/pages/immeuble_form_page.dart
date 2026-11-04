import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/immeuble.dart';
import '../providers/immeuble_providers.dart';

/// Création (immeuble nul) ou modification d'un immeuble.
class ImmeubleFormPage extends ConsumerStatefulWidget {
  final Immeuble? immeuble;

  const ImmeubleFormPage({super.key, this.immeuble});

  @override
  ConsumerState<ImmeubleFormPage> createState() => _ImmeubleFormPageState();
}

class _ImmeubleFormPageState extends ConsumerState<ImmeubleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.immeuble?.nom);
  late final _adresse = TextEditingController(text: widget.immeuble?.adresse);
  late final _commune = TextEditingController(text: widget.immeuble?.commune);
  late final _ville = TextEditingController(text: widget.immeuble?.ville ?? 'Abidjan');
  late final _etages = TextEditingController(text: widget.immeuble?.nombreEtages?.toString());
  late final _annee =
      TextEditingController(text: widget.immeuble?.anneeConstruction?.toString());
  late final _description = TextEditingController(text: widget.immeuble?.description);
  bool _envoi = false;

  bool get _edition => widget.immeuble != null;

  @override
  void dispose() {
    for (final c in [_nom, _adresse, _commune, _ville, _etages, _annee, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _texte(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final immeuble = Immeuble(
      nom: _nom.text.trim(),
      adresse: _texte(_adresse),
      commune: _texte(_commune),
      ville: _texte(_ville),
      nombreEtages: int.tryParse(_etages.text),
      anneeConstruction: int.tryParse(_annee.text),
      description: _texte(_description),
    );
    final repo = ref.read(immeubleRepositoryProvider);
    final result = _edition
        ? await repo.update(widget.immeuble!.id!, immeuble)
        : await repo.create(immeuble);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold(
      (f) => showError(context, f.message),
      (_) {
        ref.invalidate(immeublesListeProvider);
        showSuccess(context, _edition ? 'Immeuble modifié.' : 'Immeuble créé.');
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: _edition ? 'Modifier l\'immeuble' : 'Nouvel immeuble'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            ChampTexte(controller: _nom, label: 'Nom', obligatoire: true),
            kGapChamps,
            ChampTexte(controller: _adresse, label: 'Adresse'),
            kGapChamps,
            Row(children: [
              Expanded(child: ChampTexte(controller: _commune, label: 'Commune')),
              const SizedBox(width: 12),
              Expanded(child: ChampTexte(controller: _ville, label: 'Ville')),
            ]),
            kGapChamps,
            Row(children: [
              Expanded(child: ChampEntier(controller: _etages, label: 'Nombre d\'étages')),
              const SizedBox(width: 12),
              Expanded(child: ChampEntier(controller: _annee, label: 'Année de construction')),
            ]),
            kGapChamps,
            ChampTexte(controller: _description, label: 'Description', maxLines: 3),
            const SizedBox(height: 24),
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
