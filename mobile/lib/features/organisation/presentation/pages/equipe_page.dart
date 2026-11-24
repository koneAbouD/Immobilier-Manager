import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../../core/error/failure.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/organisation.dart';
import '../providers/organisation_providers.dart';
import '../widgets/carte_organisation.dart';

/// Équipe de l'organisation : collaborateurs, rôles et accès. Réservé aux
/// administrateurs (le backend applique les mêmes règles).
class EquipePage extends ConsumerWidget {
  const EquipePage({super.key});

  Future<void> _inviter(BuildContext context, WidgetRef ref) async {
    final membre = await afficherFeuille<MembreEquipe>(context, builder: (_) => const _FeuilleInvitation());
    if (membre == null || !context.mounted) return;
    ref.invalidate(membresProvider);
    ref.invalidate(organisationCouranteProvider);
    if (membre.motDePasseTemporaire != null) {
      await _identifiants(context, membre);
    } else {
      showSuccess(context, '${membre.nomComplet} a rejoint l\'équipe avec son compte existant.');
    }
  }

  /// Le mot de passe provisoire n'est montré qu'une fois : on le rend facile à transmettre.
  Future<void> _identifiants(BuildContext context, MembreEquipe membre) {
    final texte = 'Bonjour ${membre.prenom ?? ''}, votre accès à Immobilier Manager est prêt.\n'
        'Identifiant : ${membre.identifiant}\nMot de passe provisoire : ${membre.motDePasseTemporaire}\n'
        'Pensez à le changer depuis Réglages › Mot de passe.';
    return informer(
      context,
      titre: 'Compte créé',
      icone: Icons.key_rounded,
      contenu: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Transmettez ces identifiants à ${membre.nomComplet}. Le mot de passe ne sera plus affiché.',
            style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.label)),
        const SizedBox(height: 14),
        LigneInfo('Identifiant', membre.identifiant),
        LigneInfo('Mot de passe', membre.motDePasseTemporaire, fort: true),
        const SizedBox(height: 10),
        BoutonSecondaire(
          label: 'Copier le message',
          icon: Icons.copy_rounded,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: texte));
            if (context.mounted) showSuccess(context, 'Message copié.');
          },
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membres = ref.watch(membresProvider);
    final organisation = ref.watch(organisationCouranteProvider).valueOrNull;
    return Scaffold(
      appBar: AppHeader(
        title: 'Équipe',
        action: AppHeaderAction(icon: Icons.person_add_alt_1_rounded, onTap: () => _inviter(context, ref)),
      ),
      body: membres.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(membresProvider)),
        data: (liste) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(membresProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              if (organisation != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    organisation.abonnement.plan.membresMax == null
                        ? '${organisation.abonnement.membres} utilisateur(s) actif(s)'
                        : '${organisation.abonnement.membres} / ${organisation.abonnement.plan.membresMax} '
                            'utilisateurs actifs (formule ${organisation.abonnement.plan.libelle})',
                    style: TextStyle(fontSize: 13, color: AppColors.label),
                  ),
                ),
              for (final m in liste) _LigneMembre(membre: m),
              const SizedBox(height: 8),
              BoutonSecondaire(
                label: 'Inviter un collaborateur',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => _inviter(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneMembre extends ConsumerWidget {
  final MembreEquipe membre;
  const _LigneMembre({required this.membre});

  Future<void> _actions(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionOrganisationProvider).valueOrNull;
    final moi = session?.profil.id;
    final monRole = ref.read(monRoleProvider);
    if (membre.utilisateurId == moi) {
      showError(context, 'Votre propre adhésion se modifie par le propriétaire du compte.');
      return;
    }
    if (membre.role == RoleMembre.proprietaire) {
      showError(context, 'Le propriétaire ne peut être ni modifié ni retiré.');
      return;
    }
    if (membre.role == RoleMembre.admin && monRole != RoleMembre.proprietaire) {
      showError(context, 'Seul le propriétaire modifie un administrateur.');
      return;
    }
    final repo = ref.read(organisationRepositoryProvider);
    final choix = await afficherFeuille<String>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(membre.nomComplet, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(membre.identifiant),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Changer le rôle'),
            onTap: () => Navigator.pop(ctx, 'role'),
          ),
          ListTile(
            leading: Icon(membre.actif ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded),
            title: Text(membre.actif ? 'Suspendre l\'accès' : 'Rétablir l\'accès'),
            onTap: () => Navigator.pop(ctx, 'actif'),
          ),
          if (monRole == RoleMembre.proprietaire && membre.actif)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Transmettre la propriété'),
              onTap: () => Navigator.pop(ctx, 'propriete'),
            ),
          ListTile(
            leading: Icon(Icons.person_remove_outlined, color: AppColors.error),
            title: Text('Retirer de l\'équipe', style: TextStyle(color: AppColors.error)),
            onTap: () => Navigator.pop(ctx, 'retirer'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choix == null || !context.mounted) return;

    switch (choix) {
      case 'role':
        final roles = [if (monRole == RoleMembre.proprietaire) RoleMembre.admin, RoleMembre.gestionnaire, RoleMembre.lecteur];
        final role = await afficherFeuille<RoleMembre>(context, builder: (ctx) => _ChoixRole(roles: roles, actuel: membre.role));
        if (role == null || role == membre.role || !context.mounted) return;
        final r = await repo.modifierMembre(membre.id, role: role);
        if (context.mounted) _resultat(context, ref, r, 'Rôle modifié.');
      case 'actif':
        final r = await repo.modifierMembre(membre.id, actif: !membre.actif);
        if (context.mounted) _resultat(context, ref, r, membre.actif ? 'Accès suspendu.' : 'Accès rétabli.');
      case 'propriete':
        final ok = await confirmer(context,
            titre: 'Transmettre la propriété ?',
            message: '${membre.nomComplet} deviendra propriétaire du compte (abonnement, équipe). '
                'Vous deviendrez administrateur.',
            action: 'Transmettre',
            icone: Icons.workspace_premium_outlined);
        if (!ok || !context.mounted) return;
        final r = await repo.transfererPropriete(membre.id);
        if (context.mounted) _resultat(context, ref, r, 'Propriété transmise.');
        // Mon propre rôle a changé : la session est rechargée.
        ref.invalidate(sessionOrganisationProvider);
      case 'retirer':
        final ok = await confirmer(context,
            titre: 'Retirer ${membre.nomComplet} ?',
            message: 'Il n\'aura plus accès à l\'organisation. Son compte et ses saisies passées sont conservés.',
            action: 'Retirer',
            destructive: true);
        if (!ok || !context.mounted) return;
        final r = await repo.retirerMembre(membre.id);
        if (context.mounted) _resultat(context, ref, r, 'Membre retiré.');
    }
  }

  void _resultat(BuildContext context, WidgetRef ref, Either<Failure, Object?> result, String succes) {
    result.fold((f) => showError(context, f.message), (_) {
      ref.invalidate(membresProvider);
      ref.invalidate(organisationCouranteProvider);
      showSuccess(context, succes);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moi = ref.watch(sessionOrganisationProvider).valueOrNull?.profil.id == membre.utilisateurId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _actions(context, ref),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Opacity(
              opacity: membre.actif ? 1 : 0.55,
              child: Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: membre.role.couleur.withValues(alpha: 0.14),
                  child: Text(membre.initiales,
                      style: TextStyle(fontWeight: FontWeight.w800, color: membre.role.couleur)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(moi ? '${membre.nomComplet} (vous)' : membre.nomComplet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
                    const SizedBox(height: 2),
                    Text(membre.identifiant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: AppColors.label)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      PastilleRole(membre.role),
                      if (!membre.actif)
                        Text('Accès suspendu',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.error)),
                      if (membre.actif)
                        Text(
                          membre.derniereConnexion == null
                              ? 'Jamais connecté'
                              : 'Vu le ${formatDate(membre.derniereConnexion)}',
                          style: TextStyle(fontSize: 11.5, color: AppColors.hint),
                        ),
                    ]),
                  ]),
                ),
                if (!moi && membre.role != RoleMembre.proprietaire)
                  Icon(Icons.more_vert_rounded, color: AppColors.hint),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoixRole extends StatelessWidget {
  final List<RoleMembre> roles;
  final RoleMembre? actuel;

  const _ChoixRole({required this.roles, this.actuel});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: EnteteFeuille(icone: Icons.badge_outlined, titre: 'Rôle'),
          ),
          for (final r in roles)
            ListTile(
              leading: Icon(r.icone, color: r.couleur),
              title: Text(r.libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(r.description),
              trailing: r == actuel ? Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(context, r),
            ),
          const SizedBox(height: 8),
        ]),
      );
}

/// Feuille d'invitation : renvoie le membre créé.
class _FeuilleInvitation extends ConsumerStatefulWidget {
  const _FeuilleInvitation();

  @override
  ConsumerState<_FeuilleInvitation> createState() => _FeuilleInvitationState();
}

class _FeuilleInvitationState extends ConsumerState<_FeuilleInvitation> {
  final _formKey = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  RoleMembre _role = RoleMembre.gestionnaire;
  bool _envoi = false;

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final result = await ref.read(organisationRepositoryProvider).ajouterMembre(
        email: _email.text.trim(), prenom: _prenom.text.trim(), nom: _nom.text.trim(), role: _role);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (m) => Navigator.pop(context, m));
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      if (ref.watch(monRoleProvider) == RoleMembre.proprietaire) RoleMembre.admin,
      RoleMembre.gestionnaire,
      RoleMembre.lecteur,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const EnteteFeuille(
              icone: Icons.person_add_alt_1_rounded,
              titre: 'Inviter un collaborateur',
              sousTitre: 'Il rejoindra votre organisation',
            ),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ChampTexte(controller: _prenom, label: 'Prénom', obligatoire: true)),
              const SizedBox(width: 12),
              Expanded(child: ChampTexte(controller: _nom, label: 'Nom', obligatoire: true)),
            ]),
            kGapChamps,
            ChampTexte(
              controller: _email,
              label: 'E-mail',
              obligatoire: true,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                  ? null
                  : 'Adresse e-mail invalide.',
            ),
            kGapChamps,
            ChampChoix<RoleMembre>(
              label: 'Rôle',
              valeur: _role,
              options: roles,
              libelle: (r) => '${r.libelle} — ${r.description}',
              obligatoire: true,
              onChanged: (r) => setState(() => _role = r ?? _role),
            ),
            const SizedBox(height: 10),
            Text(
              'S\'il n\'a pas encore de compte, un mot de passe provisoire vous sera affiché pour le lui transmettre.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.hint),
            ),
            const SizedBox(height: 16),
            BoutonPrincipal(label: 'Inviter', icon: Icons.send_rounded, loading: _envoi, onPressed: _envoyer),
          ]),
        ),
      ),
    );
  }
}
