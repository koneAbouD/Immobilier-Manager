import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/entities/organisation.dart';
import '../providers/organisation_providers.dart';

/// Adresse commerciale à qui demander un changement de formule
/// (`--dart-define=CONTACT_COMMERCIAL=ventes@exemple.com`). Vide : le bouton
/// de contact n'apparaît pas.
const _kContactCommercial = String.fromEnvironment('CONTACT_COMMERCIAL');

/// Formule, état et consommation de l'abonnement, et formules disponibles.
class AbonnementPage extends ConsumerWidget {
  const AbonnementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organisation = ref.watch(organisationCouranteProvider);
    return Scaffold(
      appBar: AppHeader(title: 'Abonnement'),
      body: organisation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: '$e', onRetry: () => ref.invalidate(organisationCouranteProvider)),
        data: (o) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(organisationCouranteProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _CarteFormule(organisation: o),
              if (o.abonnement.motifRestriction != null) ...[
                const SizedBox(height: 12),
                AppErrorBanner(message: o.abonnement.motifRestriction!),
              ],
              const SizedBox(height: 16),
              _Consommation(abonnement: o.abonnement),
              const SizedBox(height: 20),
              Text('FORMULES',
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: AppColors.label)),
              const SizedBox(height: 10),
              _Formules(actuelle: o.abonnement.plan.code),
              const SizedBox(height: 12),
              if (_kContactCommercial.isNotEmpty && ref.watch(monRoleProvider) == RoleMembre.proprietaire)
                BoutonPrincipal(
                  label: 'Changer de formule',
                  icon: Icons.mail_outline_rounded,
                  onPressed: () => launchUrl(Uri(
                    scheme: 'mailto',
                    path: _kContactCommercial,
                    queryParameters: {'subject': 'Abonnement — ${o.nom} (n° ${o.id})'},
                  )),
                )
              else
                Text(
                  'Le changement de formule se fait auprès de l\'éditeur ; le propriétaire du compte '
                  'en fait la demande.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.hint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteFormule extends StatelessWidget {
  final OrganisationCourante organisation;
  const _CarteFormule({required this.organisation});

  @override
  Widget build(BuildContext context) {
    final a = organisation.abonnement;
    final echeance = a.statut == StatutAbonnement.essai ? a.essaiFinLe : a.abonnementFinLe;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Formule ${a.plan.libelle}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(a.statut.libelle,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 14),
        Text(organisation.nom,
            style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 4),
        Text(
          switch ((a.statut, echeance, a.joursRestants)) {
            (StatutAbonnement.essai, final DateTime fin, final int jours) =>
              'Essai jusqu\'au ${formatDate(fin)} · $jours jour${jours > 1 ? 's' : ''} restant${jours > 1 ? 's' : ''}',
            (StatutAbonnement.actif, final DateTime fin, _) => 'Renouvellement le ${formatDate(fin)}',
            (StatutAbonnement.actif, null, _) => 'Sans échéance',
            _ => a.statut.libelle,
          },
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ]),
    );
  }
}

class _Consommation extends StatelessWidget {
  final Abonnement abonnement;
  const _Consommation({required this.abonnement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Consommation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
        const SizedBox(height: 12),
        _Jauge(icone: Icons.door_front_door_outlined, libelle: 'Lots', valeur: abonnement.lots,
            max: abonnement.plan.lotsMax),
        _Jauge(icone: Icons.group_outlined, libelle: 'Utilisateurs', valeur: abonnement.membres,
            max: abonnement.plan.membresMax),
        _Jauge(icone: Icons.apartment_rounded, libelle: 'Biens', valeur: abonnement.biens, max: null),
      ]),
    );
  }
}

class _Jauge extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final int valeur;
  final int? max;

  const _Jauge({required this.icone, required this.libelle, required this.valeur, required this.max});

  @override
  Widget build(BuildContext context) {
    final ratio = max == null || max == 0 ? null : (valeur / max!).clamp(0.0, 1.0);
    final couleur = ratio == null
        ? AppColors.primary
        : ratio >= 1
            ? AppColors.error
            : ratio >= 0.8
                ? AppColors.warning
                : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(children: [
          Icon(icone, size: 18, color: AppColors.label),
          const SizedBox(width: 8),
          Expanded(child: Text(libelle, style: TextStyle(fontSize: 13.5, color: AppColors.dark))),
          Text(max == null ? '$valeur' : '$valeur / $max',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: couleur)),
        ]),
        if (ratio != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: couleur,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ]),
    );
  }
}

class _Formules extends ConsumerWidget {
  final String actuelle;
  const _Formules({required this.actuelle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    return plans.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('$e', style: TextStyle(color: AppColors.error)),
      data: (liste) => Column(
        children: [
          for (final p in liste)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: p.code == actuelle ? AppColors.primary : AppColors.border,
                    width: p.code == actuelle ? 1.6 : 1),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(p.libelle,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
                      if (p.code == actuelle) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '${p.lotsMax == null ? 'Lots illimités' : '${p.lotsMax} lots'} · '
                      '${p.membresMax == null ? 'utilisateurs illimités' : '${p.membresMax} utilisateur${p.membresMax! > 1 ? 's' : ''}'}',
                      style: TextStyle(fontSize: 12.5, color: AppColors.label),
                    ),
                  ]),
                ),
                Text(
                  p.surDevis ? 'Sur devis' : p.gratuit ? 'Gratuit' : '${formatMontant(p.tarifMensuel)}\n/ mois',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
