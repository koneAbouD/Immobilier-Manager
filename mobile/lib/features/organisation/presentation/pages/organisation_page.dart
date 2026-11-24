import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/organisation.dart';
import '../providers/organisation_providers.dart';
import '../widgets/carte_organisation.dart';

/// Identité de l'organisation : c'est le bailleur imprimé sur les contrats et
/// les quittances (nom, représentant, coordonnées, ville de signature, logo).
/// Modifiable par les administrateurs, consultable par tous.
class OrganisationPage extends ConsumerWidget {
  const OrganisationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organisation = ref.watch(organisationCouranteProvider);
    return Scaffold(
      appBar: AppHeader(title: 'Mon organisation'),
      body: organisation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(organisationCouranteProvider)),
        data: (o) => _Formulaire(organisation: o, modifiable: ref.watch(monRoleProvider).estAdmin),
      ),
    );
  }
}

class _Formulaire extends ConsumerStatefulWidget {
  final OrganisationCourante organisation;
  final bool modifiable;

  const _Formulaire({required this.organisation, required this.modifiable});

  @override
  ConsumerState<_Formulaire> createState() => _FormulaireState();
}

class _FormulaireState extends ConsumerState<_Formulaire> {
  final _formKey = GlobalKey<FormState>();
  late final _nom = TextEditingController(text: widget.organisation.nom);
  late final _representant = TextEditingController(text: widget.organisation.representant);
  late final _email = TextEditingController(text: widget.organisation.email);
  late final _telephone = TextEditingController(text: widget.organisation.telephone);
  late final _adresse = TextEditingController(text: widget.organisation.adresse);
  late final _ville = TextEditingController(text: widget.organisation.ville);
  bool _envoi = false;
  bool _logoEnCours = false;

  @override
  void dispose() {
    for (final c in [_nom, _representant, _email, _telephone, _adresse, _ville]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _texte(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final result = await ref.read(organisationRepositoryProvider).modifier({
      'nom': _nom.text.trim(),
      'representant': _texte(_representant),
      'email': _texte(_email),
      'telephone': _texte(_telephone),
      'adresse': _texte(_adresse),
      'ville': _texte(_ville),
      'pays': widget.organisation.pays,
      'devise': widget.organisation.devise,
    });
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (_) {
      ref.invalidate(organisationCouranteProvider);
      showSuccess(context, 'Organisation enregistrée.');
    });
  }

  Future<void> _changerLogo() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 90);
    if (image == null) return;
    setState(() => _logoEnCours = true);
    final octets = await image.readAsBytes();
    final type = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    final result = await ref.read(organisationRepositoryProvider).deposerLogo(octets, image.name, type);
    if (!mounted) return;
    setState(() => _logoEnCours = false);
    result.fold((f) => showError(context, f.message), (_) {
      ref.invalidate(organisationCouranteProvider);
      showSuccess(context, 'Logo mis à jour : il figurera sur vos prochains documents.');
    });
  }

  Future<void> _retirerLogo() async {
    final ok = await confirmer(context,
        titre: 'Retirer le logo ?', message: 'Les documents seront édités sans logo.', destructive: true);
    if (!ok) return;
    final result = await ref.read(organisationRepositoryProvider).supprimerLogo();
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) => ref.invalidate(organisationCouranteProvider));
  }

  @override
  Widget build(BuildContext context) {
    final logo = ref.watch(logoOrganisationProvider).valueOrNull;
    final lectureSeule = !widget.modifiable;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // Logo
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.blanc,
                  alignment: Alignment.center,
                  child: _logoEnCours
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : logo != null
                          ? Image.memory(logo, fit: BoxFit.contain)
                          : MonogrammeOrganisation(widget.organisation.nom, taille: 72),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Logo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 4),
                  Text('Imprimé en tête des contrats et des quittances. JPEG ou PNG, 2 Mo au plus.',
                      style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.label)),
                  if (!lectureSeule) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 4, children: [
                      TextButton.icon(
                        onPressed: _logoEnCours ? null : _changerLogo,
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(widget.organisation.logo ? 'Changer' : 'Ajouter'),
                      ),
                      if (widget.organisation.logo)
                        TextButton(
                          onPressed: _retirerLogo,
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Retirer'),
                        ),
                    ]),
                  ],
                ]),
              ),
            ]),
          ),
          IgnorePointer(
            ignoring: lectureSeule,
            child: Column(children: [
              GroupeChamps(titre: 'Bailleur', icone: Icons.business_rounded, children: [
                ChampTexte(controller: _nom, label: 'Raison sociale ou nom', obligatoire: true),
                kGapChamps,
                ChampTexte(controller: _representant, label: 'Représenté par', hint: 'Ex. M. Koné, gérant'),
              ]),
              GroupeChamps(titre: 'Coordonnées', icone: Icons.contact_mail_outlined, couleur: AppColors.info, children: [
                ChampTexte(controller: _email, label: 'E-mail', keyboardType: TextInputType.emailAddress),
                kGapChamps,
                ChampTexte(controller: _telephone, label: 'Téléphone', keyboardType: TextInputType.phone),
                kGapChamps,
                ChampTexte(controller: _adresse, label: 'Adresse', hint: 'Rue, lot, boîte postale'),
                kGapChamps,
                ChampTexte(
                  controller: _ville,
                  label: 'Ville',
                  hint: 'Ville de signature et juridiction compétente',
                ),
              ]),
            ]),
          ),
          if (lectureSeule)
            Text('Seuls les administrateurs modifient l\'organisation.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.hint))
          else
            BoutonPrincipal(
              label: 'Enregistrer',
              icon: Icons.check_rounded,
              loading: _envoi,
              onPressed: _enregistrer,
            ),
        ],
      ),
    );
  }
}
