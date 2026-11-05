import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/detail_carte.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../bail/domain/entities/bail.dart';
import '../../../bail/presentation/pages/bail_detail_page.dart';
import '../../../bail/presentation/pages/bail_form_page.dart';
import '../../../bail/presentation/providers/bail_providers.dart';
import '../../../bail/presentation/widgets/contrat_bail.dart';
import '../../../loyer/domain/entities/echeance.dart';
import '../../../loyer/domain/entities/paiement.dart';
import '../../../loyer/presentation/providers/loyer_providers.dart';
import '../../../loyer/presentation/widgets/encaissement_sheet.dart';
import '../../domain/entities/locataire.dart';
import '../providers/locataire_providers.dart';
import 'locataire_form_page.dart';

/// Baux du locataire, du plus récent au plus ancien.
final _bauxLocataireProvider = FutureProvider.autoDispose.family<List<Bail>, int>((ref, id) async {
  final result = await ref.watch(bailRepositoryProvider).getPage(size: 50, locataireId: id);
  return result.fold((f) => throw f.message, (p) => p.content);
});

/// Loyers encore à encaisser du locataire, tous baux confondus.
final _aEncaisserLocataireProvider =
    FutureProvider.autoDispose.family<List<Echeance>, int>((ref, id) async {
  final result =
      await ref.watch(loyerRepositoryProvider).getEcheances(size: 60, locataireId: id, aEncaisser: true);
  return result.fold((f) => throw f.message, (p) => p.content);
});

final _paiementsLocataireProvider =
    FutureProvider.autoDispose.family<List<Paiement>, int>((ref, id) async {
  final result = await ref.watch(loyerRepositoryProvider).getPaiements(size: 30, locataireId: id);
  return result.fold((f) => throw f.message, (p) => p.content);
});

enum _Onglet { baux, paiements, infos }

/// Fiche d'un locataire : contacts en un geste, ce qu'il doit, puis ses baux,
/// ses paiements et ses informations dans trois onglets.
class LocataireDetailPage extends ConsumerStatefulWidget {
  final int locataireId;

  const LocataireDetailPage({super.key, required this.locataireId});

  @override
  ConsumerState<LocataireDetailPage> createState() => _LocataireDetailPageState();
}

class _LocataireDetailPageState extends ConsumerState<LocataireDetailPage> {
  _Onglet _onglet = _Onglet.baux;

  int get _id => widget.locataireId;

  void _rafraichir() {
    ref.invalidate(locataireDetailProvider(_id));
    ref.invalidate(_bauxLocataireProvider(_id));
    ref.invalidate(_aEncaisserLocataireProvider(_id));
    ref.invalidate(_paiementsLocataireProvider(_id));
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _rafraichir();
  }

  Future<void> _encaisser(Echeance e) async {
    if (await ouvrirEcheance(context, e)) _rafraichir();
  }

  Future<void> _supprimer(Locataire l) async {
    final ok = await confirmer(context,
        titre: 'Supprimer le locataire ?',
        message: '${l.nomComplet} sera définitivement supprimé.',
        action: 'Supprimer',
        destructive: true);
    if (!ok || !mounted) return;
    final result = await ref.read(locataireRepositoryProvider).delete(l.id!);
    if (!mounted) return;
    result.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Locataire supprimé.');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(locataireDetailProvider(_id));
    return async.when(
      loading: () => const Scaffold(
          appBar: AppHeader(title: ''), body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: const AppHeader(title: ''),
          body: ErrorView(message: '$e', onRetry: _rafraichir)),
      data: (l) {
        final baux = ref.watch(_bauxLocataireProvider(_id));
        final aEncaisser = ref.watch(_aEncaisserLocataireProvider(_id));
        return Scaffold(
          appBar: AppHeader(
            title: 'Locataire',
            action: ActionsDetail(
              onModifier: () => _ouvrir(LocataireFormPage(locataire: l)),
              onSupprimer: () => _supprimer(l),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async => _rafraichir(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _Profil(locataire: l, baux: baux.valueOrNull),
                const SizedBox(height: 16),
                _Contacts(telephone: l.telephone),
                const SizedBox(height: 16),
                // Sans bail en cours ni loyer dû, il n'y a pas de solde à montrer.
                if (aEncaisser.valueOrNull != null &&
                    (aEncaisser.value!.isNotEmpty ||
                        (baux.valueOrNull?.any((b) => b.estActif) ?? false))) ...[
                  _Solde(echeances: aEncaisser.value!, onEncaisser: _encaisser),
                  const SizedBox(height: 18),
                ],
                _Onglets(
                  selection: _onglet,
                  nombreBaux: baux.valueOrNull?.length,
                  onSelected: (o) => setState(() => _onglet = o),
                ),
                const SizedBox(height: 14),
                switch (_onglet) {
                  _Onglet.baux => _OngletBaux(
                      baux: baux,
                      onRetry: () => ref.invalidate(_bauxLocataireProvider(_id)),
                      onOuvrir: (b) => _ouvrir(BailDetailPage(bailId: b.id!)),
                      onNouveau: () => _ouvrir(BailFormPage(locataireInitial: l)),
                    ),
                  _Onglet.paiements => _OngletPaiements(locataireId: _id),
                  _Onglet.infos => _OngletInfos(locataire: l),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── En-tête ─────────────────────────────────────────────────────────────────

class _Profil extends StatelessWidget {
  final Locataire locataire;
  final List<Bail>? baux;

  const _Profil({required this.locataire, required this.baux});

  @override
  Widget build(BuildContext context) {
    final premier = baux == null || baux!.isEmpty
        ? null
        : baux!.map((b) => b.dateDebut).reduce((a, b) => a.isBefore(b) ? a : b);
    final sousTitre = [
      locataire.profession,
      if (premier != null) 'Locataire depuis ${formatMois(premier).toLowerCase()}',
    ].whereType<String>().join(' · ');
    return Column(children: [
      Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
        child: Text(locataire.initiales,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
      ),
      const SizedBox(height: 10),
      Text(locataire.nomComplet,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark, letterSpacing: -0.4)),
      if (sousTitre.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(sousTitre,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: AppColors.label)),
      ],
    ]);
  }
}

/// Appeler, écrire sur WhatsApp ou envoyer un SMS au locataire.
class _Contacts extends StatelessWidget {
  final String telephone;

  const _Contacts({required this.telephone});

  /// Numéro international sans « + » pour wa.me ; les numéros ivoiriens à dix
  /// chiffres reçoivent l'indicatif 225.
  String get _whatsapp {
    final chiffres = telephone.replaceAll(RegExp(r'[^0-9]'), '');
    if (telephone.trim().startsWith('+') || chiffres.startsWith('00')) {
      return chiffres.replaceFirst(RegExp(r'^00'), '');
    }
    return chiffres.length == 10 ? '225$chiffres' : chiffres;
  }

  Future<void> _lancer(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showError(context, 'Aucune application ne peut ouvrir ce lien.');
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _BoutonContact(
          icone: Icons.call_outlined,
          libelle: 'Appeler',
          onTap: () => _lancer(context, Uri(scheme: 'tel', path: telephone))),
      const SizedBox(width: 10),
      _BoutonContact(
          icone: Icons.chat_outlined,
          libelle: 'WhatsApp',
          onTap: () => _lancer(context, Uri.parse('https://wa.me/$_whatsapp'))),
      const SizedBox(width: 10),
      _BoutonContact(
          icone: Icons.sms_outlined,
          libelle: 'SMS',
          onTap: () => _lancer(context, Uri(scheme: 'sms', path: telephone))),
    ]);
  }
}

class _BoutonContact extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;

  const _BoutonContact({required this.icone, required this.libelle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Icon(icone, size: 21, color: AppColors.primaryDark),
              const SizedBox(height: 5),
              Text(libelle,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.dark)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Ce que doit le locataire : retard en rouge, prochain loyer à venir, ou à jour.
class _Solde extends StatelessWidget {
  final List<Echeance> echeances;
  final ValueChanged<Echeance> onEncaisser;

  const _Solde({required this.echeances, required this.onEncaisser});

  @override
  Widget build(BuildContext context) {
    final retards = echeances.where((e) => e.enRetard).toList();
    // La liste vient du plus récent au plus ancien : on encaisse le plus ancien d'abord.
    final aRegler = retards.isNotEmpty ? retards.last : (echeances.isEmpty ? null : echeances.last);
    final enRetard = retards.isNotEmpty;
    final couleur = enRetard ? AppColors.error : (aRegler != null ? AppColors.info : AppColors.positive);
    final montant = enRetard
        ? retards.fold<double>(0, (s, e) => s + e.resteDu)
        : echeances.fold<double>(0, (s, e) => s + e.resteDu);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              enRetard
                  ? '${retards.length} loyer(s) en retard'
                  : aRegler != null
                      ? 'Prochain loyer · échéance le ${formatDate(aRegler.dateEcheance)}'
                      : 'Tous les loyers sont réglés',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: couleur),
            ),
            const SizedBox(height: 3),
            Text(aRegler != null ? formatMontant(montant) : 'À jour',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark, letterSpacing: -0.4)),
          ]),
        ),
        if (aRegler != null)
          FilledButton.icon(
            onPressed: () => onEncaisser(aRegler),
            icon: const Icon(Icons.payments_outlined, size: 17),
            label: const Text('Encaisser'),
            style: FilledButton.styleFrom(
              backgroundColor: enRetard ? AppColors.error : null,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          )
        else
          Icon(Icons.verified_rounded, color: AppColors.positive, size: 30),
      ]),
    );
  }
}

// ── Onglets ─────────────────────────────────────────────────────────────────

class _Onglets extends StatelessWidget {
  final _Onglet selection;
  final int? nombreBaux;
  final ValueChanged<_Onglet> onSelected;

  const _Onglets({required this.selection, required this.nombreBaux, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    String libelle(_Onglet o) => switch (o) {
          _Onglet.baux => nombreBaux == null ? 'Baux' : 'Baux ($nombreBaux)',
          _Onglet.paiements => 'Paiements',
          _Onglet.infos => 'Infos',
        };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        for (final o in _Onglet.values)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: o == selection ? AppColors.blanc : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: o == selection
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 1))
                        ]
                      : null,
                ),
                child: Text(libelle(o),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: o == selection ? FontWeight.w700 : FontWeight.w500,
                        color: o == selection ? AppColors.dark : AppColors.label)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _OngletBaux extends StatelessWidget {
  final AsyncValue<List<Bail>> baux;
  final VoidCallback onRetry;
  final ValueChanged<Bail> onOuvrir;
  final VoidCallback onNouveau;

  const _OngletBaux({
    required this.baux,
    required this.onRetry,
    required this.onOuvrir,
    required this.onNouveau,
  });

  @override
  Widget build(BuildContext context) {
    return baux.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => TextButton(onPressed: onRetry, child: Text('$e — Réessayer')),
      data: (liste) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in liste)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CarteBail(bail: b, onTap: () => onOuvrir(b)),
            ),
          if (liste.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Aucun bail pour ce locataire.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500)),
            ),
          OutlinedButton.icon(
            onPressed: onNouveau,
            icon: const Icon(Icons.draw_outlined, size: 18),
            label: const Text('Signer un nouveau bail'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un bail : logement, conditions, état du bail et de son contrat.
class _CarteBail extends StatelessWidget {
  final Bail bail;
  final VoidCallback onTap;

  const _CarteBail({required this.bail, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = bail;
    return Material(
      color: AppColors.blanc,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.home_work_outlined, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(b.logement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
              ),
              PastilleStatut(b.statut.libelle, b.statut.couleur),
            ]),
            const SizedBox(height: 6),
            Text(
              '${b.reference ?? ''} · ${formatMontant(b.montantMensuel)} / mois'
              '${b.estActif ? ' · le ${b.jourEcheance}' : ''}',
              style: TextStyle(fontSize: 12, color: AppColors.label),
            ),
            const SizedBox(height: 2),
            Text(
              b.estActif
                  ? 'Depuis le ${formatDate(b.dateDebut)}'
                  : 'Du ${formatDate(b.dateDebut)} au ${formatDate(b.dateResiliation)}',
              style: TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
            if (b.estActif) ...[
              const SizedBox(height: 10),
              StatutBadgeContrat(statut: b.statutContrat),
            ],
          ]),
        ),
      ),
    );
  }
}

class _OngletPaiements extends ConsumerWidget {
  final int locataireId;

  const _OngletPaiements({required this.locataireId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_paiementsLocataireProvider(locataireId)).when(
          loading: () => const Padding(
              padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => TextButton(
              onPressed: () => ref.invalidate(_paiementsLocataireProvider(locataireId)),
              child: Text('$e — Réessayer')),
          data: (liste) => liste.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Aucun paiement enregistré.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500)),
                )
              : Column(children: [
                  for (final p in liste)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListeCarte(
                        icon: p.annule ? Icons.block_rounded : Icons.south_west_rounded,
                        couleur: p.annule ? AppColors.hint : AppColors.positive,
                        titre: formatMois(p.periode),
                        valeur: formatMontant(p.montant),
                        barre: p.annule,
                        sousTitre: '${formatDate(p.datePaiement)} · ${p.modePaiement.libelle}'
                            '${p.reference != null ? ' · ${p.reference}' : ''}',
                        detail: p.annule
                            ? 'Annulé : ${p.motifAnnulation ?? ''}'
                            : [p.appartementReference, p.immeubleNom].whereType<String>().join(' · '),
                      ),
                    ),
                ]),
        );
  }
}

class _OngletInfos extends StatelessWidget {
  final Locataire locataire;

  const _OngletInfos({required this.locataire});

  @override
  Widget build(BuildContext context) {
    final l = locataire;
    return Column(children: [
      DetailInfoCard(titre: 'Coordonnées', icon: Icons.contact_page_outlined, children: [
        DetailInfoRow(Icons.phone_outlined, 'Téléphone', l.telephone),
        DetailInfoRow(Icons.alternate_email_rounded, 'E-mail', l.email),
        DetailInfoRow(Icons.place_outlined, 'Adresse', l.adresse),
      ]),
      DetailInfoCard(titre: 'Identité', icon: Icons.badge_outlined, children: [
        DetailInfoRow(Icons.work_outline_rounded, 'Profession', l.profession),
        DetailInfoRow(Icons.cake_outlined, 'Né(e) le',
            l.dateNaissance == null ? null : formatDate(l.dateNaissance)),
        DetailInfoRow(Icons.badge_outlined, 'Pièce',
            [l.typePiece?.libelle, l.numeroPiece].whereType<String>().join(' n° ')),
      ]),
      if (l.contactUrgenceNom != null || l.contactUrgenceTelephone != null)
        DetailInfoCard(titre: 'Contact d\'urgence', icon: Icons.emergency_outlined, children: [
          DetailInfoRow(Icons.person_outline, 'Nom', l.contactUrgenceNom),
          DetailInfoRow(Icons.phone_outlined, 'Téléphone', l.contactUrgenceTelephone),
        ]),
    ]);
  }
}
