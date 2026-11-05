import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/locataire.dart';
import '../providers/locataire_providers.dart';

class LocataireFormPage extends ConsumerStatefulWidget {
  final Locataire? locataire;

  const LocataireFormPage({super.key, this.locataire});

  @override
  ConsumerState<LocataireFormPage> createState() => _LocataireFormPageState();
}

class _LocataireFormPageState extends ConsumerState<LocataireFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final l = widget.locataire;
  late final _nom = TextEditingController(text: l?.nom);
  late final _prenom = TextEditingController(text: l?.prenom);
  late final _telephone = TextEditingController(text: l?.telephone);
  late final _email = TextEditingController(text: l?.email);
  late final _numeroPiece = TextEditingController(text: l?.numeroPiece);
  late final _profession = TextEditingController(text: l?.profession);
  late final _adresse = TextEditingController(text: l?.adresse);
  late final _urgenceNom = TextEditingController(text: l?.contactUrgenceNom);
  late final _urgenceTel = TextEditingController(text: l?.contactUrgenceTelephone);
  late TypePiece? _typePiece = l?.typePiece;
  late DateTime? _dateNaissance = l?.dateNaissance;
  bool _envoi = false;

  bool get _edition => l != null;

  @override
  void dispose() {
    for (final c in [
      _nom, _prenom, _telephone, _email, _numeroPiece, _profession, _adresse, _urgenceNom, _urgenceTel
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _texte(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final saisie = Locataire(
      nom: _nom.text.trim(),
      prenom: _prenom.text.trim(),
      telephone: _telephone.text.trim(),
      email: _texte(_email),
      typePiece: _typePiece,
      numeroPiece: _texte(_numeroPiece),
      profession: _texte(_profession),
      dateNaissance: _dateNaissance,
      adresse: _texte(_adresse),
      contactUrgenceNom: _texte(_urgenceNom),
      contactUrgenceTelephone: _texte(_urgenceTel),
    );
    final repo = ref.read(locataireRepositoryProvider);
    final result = _edition ? await repo.update(l!.id!, saisie) : await repo.create(saisie);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (cree) {
      showSuccess(context, _edition ? 'Locataire modifié.' : 'Locataire créé.');
      Navigator.pop(context, cree);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: _edition ? 'Modifier le locataire' : 'Nouveau locataire'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            GroupeChamps(titre: 'Identité', icone: Icons.person_outline_rounded, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ChampTexte(controller: _nom, label: 'Nom', obligatoire: true)),
                const SizedBox(width: 12),
                Expanded(child: ChampTexte(controller: _prenom, label: 'Prénom', obligatoire: true)),
              ]),
              kGapChamps,
              ChampDate(
                label: 'Date de naissance',
                valeur: _dateNaissance,
                derniere: DateTime.now(),
                premiere: DateTime(1920),
                onChanged: (d) => setState(() => _dateNaissance = d),
              ),
              kGapChamps,
              ChampTexte(controller: _profession, label: 'Profession', hint: 'Ex. Comptable'),
            ]),
            GroupeChamps(titre: 'Coordonnées', icone: Icons.contact_mail_outlined, couleur: AppColors.info, children: [
              ChampTexte(
                  controller: _telephone,
                  label: 'Téléphone',
                  hint: '07 00 00 00 00',
                  obligatoire: true,
                  keyboardType: TextInputType.phone),
              kGapChamps,
              ChampTexte(
                controller: _email,
                label: 'E-mail',
                hint: 'exemple@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.trim().isNotEmpty && !v.contains('@')
                    ? 'Adresse e-mail invalide.'
                    : null,
              ),
              kGapChamps,
              ChampTexte(controller: _adresse, label: 'Adresse', hint: 'Commune, quartier, rue'),
            ]),
            GroupeChamps(titre: 'Pièce d\'identité', icone: Icons.badge_outlined, couleur: AppColors.warning, children: [
              ChampChoix<TypePiece>(
                label: 'Type de pièce',
                valeur: _typePiece,
                options: TypePiece.values,
                libelle: (t) => t.libelle,
                onChanged: (t) => setState(() => _typePiece = t),
              ),
              kGapChamps,
              ChampTexte(controller: _numeroPiece, label: 'Numéro de pièce', hint: 'Ex. CI0012345'),
            ]),
            GroupeChamps(titre: 'Contact d\'urgence', icone: Icons.emergency_outlined, couleur: AppColors.error, children: [
              ChampTexte(controller: _urgenceNom, label: 'Nom', hint: 'Personne à prévenir'),
              kGapChamps,
              ChampTexte(
                  controller: _urgenceTel,
                  label: 'Téléphone',
                  hint: '07 00 00 00 00',
                  keyboardType: TextInputType.phone),
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
