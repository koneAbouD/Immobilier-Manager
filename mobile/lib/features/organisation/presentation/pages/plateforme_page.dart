import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/date_filter_dialogs.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../domain/entities/organisation.dart';
import '../providers/organisation_providers.dart';
import '../widgets/carte_organisation.dart';

/// Back-office de l'éditeur (rôle SUPER_ADMIN) : organisations clientes, leur
/// consommation et leur abonnement. Aucune donnée métier n'y est visible.
class PlateformePage extends ConsumerStatefulWidget {
  const PlateformePage({super.key});

  @override
  ConsumerState<PlateformePage> createState() => _PlateformePageState();
}

class _PlateformePageState extends ConsumerState<PlateformePage> {
  final _liste = GlobalKey<PagedListViewState<OrganisationCourante>>();
  String _recherche = '';

  Future<void> _modifier(OrganisationCourante o) async {
    final modifiee = await afficherFeuille<OrganisationCourante>(context, builder: (_) => _FeuilleAbonnement(o));
    if (modifiee != null && mounted) {
      showSuccess(context, 'Abonnement de ${modifiee.nom} mis à jour.');
      _liste.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(organisationRepositoryProvider);
    return Scaffold(
      appBar: AppHeader(title: 'Plateforme', badge: 'Éditeur'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: ChampRecherche(
            hint: 'Organisation, e-mail, téléphone…',
            onChanged: (v) => setState(() => _recherche = v),
          ),
        ),
        Expanded(
          child: PagedListView<OrganisationCourante>(
            key: _liste,
            filtresKey: _recherche,
            emptyMessage: 'Aucune organisation.',
            emptyIcon: Icons.domain_rounded,
            fetcher: (page, size) => repo.organisationsPlateforme(page: page, size: size, recherche: _recherche),
            itemBuilder: (context, o) => _LigneOrganisation(organisation: o, onTap: () => _modifier(o)),
          ),
        ),
      ]),
    );
  }
}

class _LigneOrganisation extends StatelessWidget {
  final OrganisationCourante organisation;
  final VoidCallback onTap;

  const _LigneOrganisation({required this.organisation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = organisation.abonnement;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              MonogrammeOrganisation(organisation.nom),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(organisation.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Text(organisation.email ?? organisation.telephone ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: AppColors.label)),
                  const SizedBox(height: 6),
                  Text('${a.plan.libelle} · ${a.lots} lot(s) · ${a.membres} utilisateur(s)',
                      style: TextStyle(fontSize: 12, color: AppColors.hint)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: a.statut.couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(a.statut.libelle,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: a.statut.couleur)),
                ),
                if (a.joursRestants != null) ...[
                  const SizedBox(height: 4),
                  Text('${a.joursRestants} j', style: TextStyle(fontSize: 11.5, color: AppColors.hint)),
                ],
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FeuilleAbonnement extends ConsumerStatefulWidget {
  final OrganisationCourante organisation;
  const _FeuilleAbonnement(this.organisation);

  @override
  ConsumerState<_FeuilleAbonnement> createState() => _FeuilleAbonnementState();
}

class _FeuilleAbonnementState extends ConsumerState<_FeuilleAbonnement> {
  late String _plan = widget.organisation.abonnement.plan.code;
  late StatutAbonnement _statut = widget.organisation.abonnement.statut;
  late DateTime? _essaiFinLe = widget.organisation.abonnement.essaiFinLe;
  late DateTime? _abonnementFinLe = widget.organisation.abonnement.abonnementFinLe;
  bool _envoi = false;

  Future<DateTime?> _date(DateTime? initiale) => showDialog<DateTime>(
        context: context,
        builder: (_) => SingleDatePickerDialog(initialDate: initiale ?? DateTime.now()),
      );

  Future<void> _valider() async {
    setState(() => _envoi = true);
    final result = await ref.read(organisationRepositoryProvider).modifierAbonnement(widget.organisation.id,
        plan: _plan, statut: _statut.code, essaiFinLe: _essaiFinLe, abonnementFinLe: _abonnementFinLe);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (o) => Navigator.pop(context, o));
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider).valueOrNull ?? const <Plan>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        EnteteFeuille(
            icone: Icons.workspace_premium_outlined, titre: 'Abonnement', sousTitre: widget.organisation.nom),
        const SizedBox(height: 16),
        ChampChoix<String>(
          label: 'Formule',
          valeur: _plan,
          options: plans.map((p) => p.code).toList(),
          libelle: (c) => plans.firstWhere((p) => p.code == c).libelle,
          obligatoire: true,
          onChanged: (c) => setState(() => _plan = c ?? _plan),
        ),
        kGapChamps,
        ChampChoix<StatutAbonnement>(
          label: 'Statut',
          valeur: _statut,
          options: StatutAbonnement.values,
          libelle: (s) => s.libelle,
          obligatoire: true,
          onChanged: (s) => setState(() => _statut = s ?? _statut),
        ),
        kGapChamps,
        if (_statut == StatutAbonnement.essai)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.hourglass_bottom_rounded),
            title: const Text('Fin de l\'essai'),
            subtitle: Text(formatDate(_essaiFinLe)),
            onTap: () async {
              final d = await _date(_essaiFinLe);
              if (d != null) setState(() => _essaiFinLe = d);
            },
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat_rounded),
            title: const Text('Fin de la période payée'),
            subtitle: Text(_abonnementFinLe == null ? 'Sans échéance' : formatDate(_abonnementFinLe)),
            trailing: _abonnementFinLe == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _abonnementFinLe = null)),
            onTap: () async {
              final d = await _date(_abonnementFinLe);
              if (d != null) setState(() => _abonnementFinLe = d);
            },
          ),
        const SizedBox(height: 12),
        BoutonPrincipal(label: 'Enregistrer', icon: Icons.check_rounded, loading: _envoi, onPressed: _valider),
      ]),
    );
  }
}
