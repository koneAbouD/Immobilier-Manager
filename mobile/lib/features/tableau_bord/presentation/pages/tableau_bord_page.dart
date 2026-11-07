import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/page_result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../../screens/section_page.dart';
import '../../../immeuble/presentation/pages/immeubles_page.dart';
import '../../../locataire/presentation/pages/locataire_detail_page.dart';
import '../../../locataire/presentation/pages/locataires_page.dart';
import '../../../loyer/domain/entities/echeance.dart';
import '../../../loyer/domain/entities/paiement.dart';
import '../../../loyer/presentation/pages/loyers_page.dart';
import '../../../loyer/presentation/widgets/encaissement_sheet.dart';
import '../../../maintenance/presentation/pages/maintenances_page.dart';
import '../../domain/entities/tableau_bord.dart';
import '../providers/tableau_bord_providers.dart';

/// Sections de l'application, ouvertes en pages depuis l'accueil.
enum _Section {
  biens('Biens immobiliers', Icons.apartment_rounded, 'Biens'),
  locataires('Locataires', Icons.people_alt_outlined, 'Locataires'),
  loyers('Loyers', Icons.account_balance_wallet_outlined, 'Loyers'),
  travaux('Maintenances', Icons.build_outlined, 'Travaux');

  final String titre;
  final IconData icone;
  final String libelle;
  const _Section(this.titre, this.icone, this.libelle);

  Widget get page => switch (this) {
        biens => const ImmeublesPage(),
        locataires => const LocatairesPage(),
        loyers => const LoyersPage(),
        travaux => const MaintenancesPage(),
      };
}

final _jourDuMois = DateFormat('EEEE d MMMM', 'fr_FR');

/// Accueil centré sur les locataires et leurs loyers : synthèse du mois, puis
/// ce qui demande une action (retards, loyers à venir), puis le journal des
/// derniers encaissements. Le parc ne vient qu'en dernier, en bref.
class TableauBordPage extends ConsumerWidget {
  const TableauBordPage({super.key});

  void _rafraichir(WidgetRef ref) {
    ref.invalidate(tableauBordProvider);
    ref.invalidate(accueilRetardsProvider);
    ref.invalidate(accueilAEncaisserProvider);
    ref.invalidate(accueilPaiementsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tableauBordProvider);

    Future<void> ouvrir(Widget page) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      _rafraichir(ref);
    }

    Future<void> encaisser(Echeance e) async {
      if (await ouvrirEcheance(context, e)) _rafraichir(ref);
    }

    void ouvrirLocataire(int id) => ouvrir(LocataireDetailPage(locataireId: id));

    // Les sections s'ouvrent par-dessus l'accueil, qui se recharge au retour.
    void ouvrirSection(_Section s) => ouvrir(SectionPage(titre: s.titre, child: s.page));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: '$e', onRetry: () => _rafraichir(ref)),
      data: (t) => RefreshIndicator(
        onRefresh: () async => _rafraichir(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
          children: [
            _Bienvenue(t: t),
            const SizedBox(height: 16),
            _CarteLoyers(t: t, onVoirLoyers: () => ouvrirSection(_Section.loyers)),
            const SizedBox(height: 18),
            _ActionsRapides(actions: [
              for (final s in _Section.values) (icon: s.icone, label: s.libelle, onTap: () => ouvrirSection(s)),
            ]),
            const SizedBox(height: 26),
            _SectionRetards(
              onEncaisser: encaisser,
              onLocataire: ouvrirLocataire,
              onToutVoir: () => ouvrirSection(_Section.loyers),
            ),
            const SizedBox(height: 26),
            _SectionAEncaisser(
              onEncaisser: encaisser,
              onToutVoir: () => ouvrirSection(_Section.loyers),
            ),
            const SizedBox(height: 26),
            _SectionPaiements(onToutVoir: () => ouvrirSection(_Section.loyers)),
            const SizedBox(height: 26),
            const _EnTeteSection(titre: 'Votre parc'),
            Row(children: [
              Expanded(
                child: _MiniIndicateur(
                  icone: Icons.people_alt_outlined,
                  couleur: AppColors.info,
                  valeur: '${t.nombreLocatairesActifs}',
                  libelle: 'Locataires',
                  onTap: () => ouvrirSection(_Section.locataires),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniIndicateur(
                  icone: Icons.apartment_rounded,
                  couleur: AppColors.primaryDark,
                  valeur: '${t.tauxOccupation} %',
                  libelle: '${t.nombreAppartementsOccupes}/${t.nombreAppartements} occupés',
                  onTap: () => ouvrirSection(_Section.biens),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniIndicateur(
                  icone: Icons.build_outlined,
                  couleur: t.maintenancesUrgentes > 0 ? AppColors.error : AppColors.warning,
                  valeur: '${t.maintenancesOuvertes}',
                  libelle: t.maintenancesUrgentes > 0
                      ? '${t.maintenancesUrgentes} urgente(s)'
                      : 'Travaux ouverts',
                  onTap: () => ouvrirSection(_Section.travaux),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── En-tête ─────────────────────────────────────────────────────────────────

/// Date du jour et phrase de synthèse : ce que le gestionnaire doit savoir en
/// ouvrant l'application.
class _Bienvenue extends StatelessWidget {
  final TableauBord t;

  const _Bienvenue({required this.t});

  @override
  Widget build(BuildContext context) {
    final jour = _jourDuMois.format(DateTime.now());
    final aJour = t.nombreEcheancesEnRetard == 0;
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(jour[0].toUpperCase() + jour.substring(1),
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.label, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            aJour ? 'Tous vos locataires sont à jour' : 'Bonjour, voici vos loyers',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
                letterSpacing: -0.5),
          ),
          if (!aJour) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.error_outline_rounded, size: 15, color: AppColors.error),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${t.nombreEcheancesEnRetard} loyer(s) en retard · '
                  '${formatMontant(t.impayes)} à recouvrer',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Carte des loyers du mois ────────────────────────────────────────────────

/// Carte en relief des loyers du mois : anneau du taux de recouvrement,
/// montant encaissé, puis reste à encaisser et impayés cumulés.
class _CarteLoyers extends StatelessWidget {
  final TableauBord t;
  final VoidCallback onVoirLoyers;

  const _CarteLoyers({required this.t, required this.onVoirLoyers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: AppColors.cardBorderGradient,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Material(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(AppColors.cardInnerRadius),
        child: InkWell(
          onTap: onVoirLoyers,
          borderRadius: BorderRadius.circular(AppColors.cardInnerRadius),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardTint,
              borderRadius: BorderRadius.circular(AppColors.cardInnerRadius),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _Anneau(taux: t.tauxRecouvrement),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Encaissé en ${formatMois(t.periode).toLowerCase()}',
                              style: TextStyle(fontSize: 12, color: AppColors.label)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatMontant(t.loyersEncaisses),
                              style: TextStyle(
                                color: AppColors.dark,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('sur ${formatMontant(t.loyersAttendus)} attendus',
                              style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _Chiffre(
                      libelle: 'Reste ce mois',
                      valeur: formatMontant(t.resteAEncaisser),
                      couleur: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Chiffre(
                      libelle: 'Impayés cumulés',
                      valeur: formatMontant(t.impayes),
                      couleur: t.impayes > 0 ? AppColors.error : AppColors.positive,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Anneau du taux de recouvrement, pourcentage au centre.
class _Anneau extends StatelessWidget {
  final int taux;

  const _Anneau({required this.taux});

  @override
  Widget build(BuildContext context) {
    final couleur = taux >= 100 ? AppColors.positive : AppColors.primary;
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _AnneauPainter(
              valeur: (taux / 100).clamp(0.0, 1.0),
              couleur: couleur,
              fond: AppColors.grey200,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$taux %',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                        letterSpacing: -0.4)),
                Text('recouvré', style: TextStyle(fontSize: 9.5, color: AppColors.label)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnneauPainter extends CustomPainter {
  final double valeur;
  final Color couleur;
  final Color fond;

  const _AnneauPainter({required this.valeur, required this.couleur, required this.fond});

  @override
  void paint(Canvas canvas, Size size) {
    const epaisseur = 8.0;
    final rect = Rect.fromLTWH(epaisseur / 2, epaisseur / 2, size.width - epaisseur,
        size.height - epaisseur);
    final trait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = epaisseur
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trait..color = fond);
    if (valeur > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * valeur, false, trait..color = couleur);
    }
  }

  @override
  bool shouldRepaint(_AnneauPainter old) =>
      old.valeur != valeur || old.couleur != couleur || old.fond != fond;
}

class _Chiffre extends StatelessWidget {
  final String libelle;
  final String valeur;
  final Color couleur;

  const _Chiffre({required this.libelle, required this.valeur, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(libelle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.label)),
            ),
          ]),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valeur,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dark)),
          ),
        ],
      ),
    );
  }
}

// ── Actions rapides ─────────────────────────────────────────────────────────

typedef _Action = ({IconData icon, String label, VoidCallback onTap});

/// Rangée des quatre sections de l'application, à la place d'une barre de
/// navigation.
class _ActionsRapides extends StatelessWidget {
  final List<_Action> actions;

  const _ActionsRapides({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: AppColors.blanc,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: a.onTap,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                        child: Icon(a.icon, size: 21, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 6),
                      Text(a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Sections ────────────────────────────────────────────────────────────────

class _EnTeteSection extends StatelessWidget {
  final String titre;
  final int? compteur;
  final Color? couleurCompteur;
  final VoidCallback? onToutVoir;

  const _EnTeteSection({
    required this.titre,
    this.compteur,
    this.couleurCompteur,
    this.onToutVoir,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(
        children: [
          Text(titre,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                  letterSpacing: -0.3)),
          if (compteur != null && compteur! > 0) ...[
            const SizedBox(width: 8),
            PastilleStatut('$compteur', couleurCompteur ?? AppColors.primary),
          ],
          const Spacer(),
          if (onToutVoir != null)
            InkWell(
              onTap: onToutVoir,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Tout voir',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Contenu d'une section qui charge sa propre liste : indicateur discret
/// pendant le chargement, ligne « Réessayer » en cas d'erreur.
class _Chargement<T> extends StatelessWidget {
  final AsyncValue<T> async;
  final VoidCallback onRetry;
  final Widget Function(T) data;

  const _Chargement({required this.async, required this.onRetry, required this.data});

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
            child: SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
      ),
      error: (e, _) => TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text('$e — Réessayer', maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Message d'une section sans contenu.
class _SectionVide extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String message;

  const _SectionVide({required this.icone, required this.couleur, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icone, color: couleur, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(
                  fontSize: 13, color: AppColors.dark, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

/// Locataires en retard de paiement, avec appel et encaissement en un geste.
class _SectionRetards extends ConsumerWidget {
  final ValueChanged<Echeance> onEncaisser;
  final ValueChanged<int> onLocataire;
  final VoidCallback onToutVoir;

  const _SectionRetards({
    required this.onEncaisser,
    required this.onLocataire,
    required this.onToutVoir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accueilRetardsProvider);
    final total = async.valueOrNull?.totalElements ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnTeteSection(
          titre: 'Loyers en retard',
          compteur: total,
          couleurCompteur: AppColors.error,
          onToutVoir: total > accueilTailleListe ? onToutVoir : null,
        ),
        _Chargement<PageResult<Echeance>>(
          async: async,
          onRetry: () => ref.invalidate(accueilRetardsProvider),
          data: (page) => page.content.isEmpty
              ? _SectionVide(
                  icone: Icons.verified_rounded,
                  couleur: AppColors.positive,
                  message: 'Aucun retard : tous les loyers échus sont réglés.',
                )
              : Column(
                  children: [
                    for (final e in page.content)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CarteRetard(
                          echeance: e,
                          onEncaisser: () => onEncaisser(e),
                          onLocataire: () => onLocataire(e.locataireId),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Carte d'un locataire en retard : qui, où, depuis quand, combien, et les
/// deux gestes utiles (appeler, encaisser).
class _CarteRetard extends StatelessWidget {
  final Echeance echeance;
  final VoidCallback onEncaisser;
  final VoidCallback onLocataire;

  const _CarteRetard({
    required this.echeance,
    required this.onEncaisser,
    required this.onLocataire,
  });

  @override
  Widget build(BuildContext context) {
    final e = echeance;
    final jours = DateUtils.dateOnly(DateTime.now())
        .difference(DateUtils.dateOnly(e.dateEcheance))
        .inDays;
    final telephone = e.locataireTelephone;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLocataire,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _Avatar(nom: e.locataireNom, couleur: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.locataireNom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dark)),
                          const SizedBox(height: 2),
                          Text(e.logement.isEmpty ? formatMois(e.periode) : e.logement,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: AppColors.label)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatMontant(e.resteDu),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error)),
                        const SizedBox(height: 3),
                        PastilleStatut(
                            jours > 0 ? '$jours j de retard' : 'En retard', AppColors.error),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Loyer de ${formatMois(e.periode)}'
                        '${e.montantPaye > 0 ? ' · payé ${formatMontant(e.montantPaye)}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: AppColors.grey500),
                      ),
                    ),
                    if (telephone != null && telephone.isNotEmpty) ...[
                      IconButton.outlined(
                        tooltip: 'Appeler',
                        onPressed: () => launchUrl(Uri(scheme: 'tel', path: telephone)),
                        icon: const Icon(Icons.call_outlined, size: 18),
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primaryDark,
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    FilledButton.icon(
                      onPressed: onEncaisser,
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Encaisser'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle:
                            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loyers du mois encore à encaisser, avant leur échéance.
class _SectionAEncaisser extends ConsumerWidget {
  final ValueChanged<Echeance> onEncaisser;
  final VoidCallback onToutVoir;

  const _SectionAEncaisser({required this.onEncaisser, required this.onToutVoir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accueilAEncaisserProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnTeteSection(titre: 'À encaisser ce mois-ci', onToutVoir: onToutVoir),
        _Chargement<List<Echeance>>(
          async: async,
          onRetry: () => ref.invalidate(accueilAEncaisserProvider),
          data: (liste) => liste.isEmpty
              ? _SectionVide(
                  icone: Icons.event_available_rounded,
                  couleur: AppColors.info,
                  message: 'Plus aucun loyer à venir ce mois-ci.',
                )
              : Column(
                  children: [
                    for (final e in liste)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListeCarte(
                          initiales: _initiales(e.locataireNom),
                          couleur: e.statut.couleur,
                          titre: e.locataireNom,
                          valeur: formatMontant(e.resteDu),
                          sousTitre: e.logement,
                          detail: 'Échéance le ${formatDate(e.dateEcheance)}',
                          badge: PastilleStatut(e.statut.libelle, e.statut.couleur),
                          onTap: () => onEncaisser(e),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Journal des derniers paiements reçus.
class _SectionPaiements extends ConsumerWidget {
  final VoidCallback onToutVoir;

  const _SectionPaiements({required this.onToutVoir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accueilPaiementsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnTeteSection(titre: 'Derniers paiements', onToutVoir: onToutVoir),
        _Chargement<List<Paiement>>(
          async: async,
          onRetry: () => ref.invalidate(accueilPaiementsProvider),
          data: (liste) => liste.isEmpty
              ? _SectionVide(
                  icone: Icons.receipt_long_outlined,
                  couleur: AppColors.grey500,
                  message: 'Aucun paiement enregistré pour le moment.',
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.blanc,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (final (i, p) in liste.indexed) ...[
                        if (i > 0)
                          Divider(height: 1, indent: 62, color: AppColors.border),
                        _LignePaiement(paiement: p),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LignePaiement extends StatelessWidget {
  final Paiement paiement;

  const _LignePaiement({required this.paiement});

  IconData get _icone => switch (paiement.modePaiement) {
        ModePaiement.especes => Icons.payments_outlined,
        ModePaiement.mobileMoney => Icons.phone_android_rounded,
        ModePaiement.virement => Icons.account_balance_outlined,
        ModePaiement.cheque => Icons.edit_note_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = paiement;
    final couleur = p.annule ? AppColors.hint : AppColors.positive;
    final barre = p.annule ? TextDecoration.lineThrough : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(p.annule ? Icons.block_rounded : _icone, size: 18, color: couleur),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.locataireNom ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                        decoration: barre)),
                const SizedBox(height: 2),
                Text(
                  p.annule
                      ? 'Annulé · ${formatMois(p.periode)}'
                      : '${formatMois(p.periode)} · ${p.modePaiement.libelle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+ ${formatMontant(p.montant)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: couleur,
                      decoration: barre)),
              const SizedBox(height: 2),
              Text(formatDate(p.datePaiement),
                  style: TextStyle(fontSize: 11, color: AppColors.grey400)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Petits éléments ─────────────────────────────────────────────────────────

/// Initiales d'un nom affiché (« Awa Koné » → « AK »).
String _initiales(String nom) {
  final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
  if (mots.isEmpty) return '?';
  final lettres = mots.length == 1 ? mots.first.substring(0, 1) : mots.first[0] + mots.last[0];
  return lettres.toUpperCase();
}

class _Avatar extends StatelessWidget {
  final String nom;
  final Color couleur;

  const _Avatar({required this.nom, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(_initiales(nom),
          style: TextStyle(color: couleur, fontSize: 14, fontWeight: FontWeight.w800)),
    );
  }
}

class _MiniIndicateur extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String valeur;
  final String libelle;
  final VoidCallback onTap;

  const _MiniIndicateur({
    required this.icone,
    required this.couleur,
    required this.valeur,
    required this.libelle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: couleur, size: 20),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valeur,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                        letterSpacing: -0.3)),
              ),
              const SizedBox(height: 2),
              Text(libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.label)),
            ],
          ),
        ),
      ),
    );
  }
}
