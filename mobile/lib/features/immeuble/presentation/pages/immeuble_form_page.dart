import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/carte_position.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/immeuble.dart';
import '../providers/immeuble_providers.dart';

/// Création (bien nul) ou modification d'un bien : immeuble, cour basse ou
/// terrain, avec sa position GPS.
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
  late TypeBien? _type = widget.immeuble?.type;
  late LatLng? _position = widget.immeuble?.position;
  bool _localisation = false;
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

  Future<void> _maPosition() async {
    setState(() => _localisation = true);
    try {
      final p = await positionActuelle();
      if (mounted) setState(() => _position = p);
    } catch (e) {
      if (mounted) showError(context, '$e');
    } finally {
      if (mounted) setState(() => _localisation = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final immeuble = Immeuble(
      nom: _nom.text.trim(),
      type: _type ?? TypeBien.immeuble,
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      adresse: _texte(_adresse),
      commune: _texte(_commune),
      ville: _texte(_ville),
      // Champs masqués pour ce type : on ne renvoie pas une ancienne saisie.
      nombreEtages: _type == TypeBien.terrain || _type == TypeBien.courBasse ? null : int.tryParse(_etages.text),
      anneeConstruction: _type == TypeBien.terrain ? null : int.tryParse(_annee.text),
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
        showSuccess(context, _edition ? 'Bien modifié.' : 'Bien créé.');
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: _edition ? 'Modifier le bien' : 'Nouveau bien'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            GroupeChamps(titre: 'Bien', icone: _type?.icone ?? Icons.apartment_rounded, children: [
              ChampChoix<TypeBien>(
                label: 'Type de bien',
                valeur: _type,
                options: TypeBien.values,
                libelle: (t) => t.libelle,
                obligatoire: true,
                onChanged: (t) => setState(() => _type = t),
              ),
              kGapChamps,
              ChampTexte(controller: _nom, label: 'Nom', hint: 'Ex. Résidence Les Palmiers', obligatoire: true),
              // Un terrain n'a ni étages ni année de construction.
              if (_type != TypeBien.terrain) ...[
                kGapChamps,
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_type != TypeBien.courBasse) ...[
                    Expanded(child: ChampEntier(controller: _etages, label: 'Nombre d\'étages')),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: ChampEntier(controller: _annee, label: 'Année de construction', hint: 'Ex. 2015')),
                ]),
              ],
            ]),
            GroupeChamps(titre: 'Adresse', icone: Icons.place_outlined, couleur: AppColors.info, children: [
              ChampTexte(controller: _adresse, label: 'Adresse', hint: 'Rue, lot, repère'),
              kGapChamps,
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ChampTexte(controller: _commune, label: 'Commune', hint: 'Ex. Cocody')),
                const SizedBox(width: 12),
                Expanded(child: ChampTexte(controller: _ville, label: 'Ville', hint: 'Ex. Abidjan')),
              ]),
              kGapChamps,
              const EtiquetteChamp('Position GPS'),
              const SizedBox(height: 6),
              CartePosition(position: _position, onTap: (p) => setState(() => _position = p)),
              const SizedBox(height: 8),
              Text(
                _position == null
                    ? 'Sur place, utilisez votre position ; sinon touchez la carte pour placer le repère.'
                    : '${formatPosition(_position!)} · touchez la carte pour ajuster',
                style: TextStyle(fontSize: 11.5, color: AppColors.label),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: BoutonSecondaire(
                    label: _localisation ? 'Localisation…' : 'Ma position',
                    icon: Icons.my_location_rounded,
                    onPressed: _localisation ? null : _maPosition,
                  ),
                ),
                if (_position != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: BoutonSecondaire(
                      label: 'Effacer',
                      icon: Icons.location_off_outlined,
                      destructive: true,
                      onPressed: () => setState(() => _position = null),
                    ),
                  ),
                ],
              ]),
            ]),
            GroupeChamps(titre: 'Description', icone: Icons.notes_rounded, couleur: AppColors.warning, children: [
              ChampTexte(controller: _description, label: 'Description', hint: 'Informations utiles', maxLines: 3),
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
