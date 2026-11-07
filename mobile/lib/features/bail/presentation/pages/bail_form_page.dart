import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/selection_page.dart';
import '../../../appartement/domain/entities/appartement.dart';
import '../../../appartement/presentation/providers/appartement_providers.dart';
import '../../../locataire/domain/entities/locataire.dart';
import '../../../locataire/presentation/providers/locataire_providers.dart';
import '../../domain/entities/bail.dart';
import '../providers/bail_providers.dart';
import '../widgets/contrat_bail.dart';

enum _Etape {
  logement('Logement'),
  locataire('Locataire'),
  conditions('Conditions'),
  contrat('Contrat');

  final String libelle;
  const _Etape(this.libelle);
}

/// Signature d'un bail en quatre étapes : logement (libre uniquement),
/// locataire, conditions (reprises du logement, ajustables), puis contrat à
/// générer, faire signer et archiver. Le bail est créé en validant les
/// conditions ; l'étape Contrat travaille sur le bail déjà signé.
class BailFormPage extends ConsumerStatefulWidget {
  final Appartement? appartementInitial;
  final Locataire? locataireInitial;

  const BailFormPage({super.key, this.appartementInitial, this.locataireInitial});

  @override
  ConsumerState<BailFormPage> createState() => _BailFormPageState();
}

class _BailFormPageState extends ConsumerState<BailFormPage> {
  final _formKey = GlobalKey<FormState>();
  late Appartement? _appartement = widget.appartementInitial;
  late Locataire? _locataire = widget.locataireInitial;
  DateTime? _dateDebut = DateTime.now();
  DateTime? _dateFin;
  final _loyer = TextEditingController();
  final _charges = TextEditingController();
  final _depot = TextEditingController();
  final _jour = TextEditingController(text: '5');
  bool _envoi = false;

  /// Bail créé à la fin de l'étape Conditions.
  Bail? _bail;
  bool _generation = false;

  late _Etape _etape = _appartement == null
      ? _Etape.logement
      : _locataire == null
      ? _Etape.locataire
      : _Etape.conditions;

  @override
  void initState() {
    super.initState();
    if (_appartement != null) _reprendreConditions(_appartement!);
  }

  @override
  void dispose() {
    for (final c in [_loyer, _charges, _depot, _jour]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reprendreConditions(Appartement a) {
    _loyer.text = a.loyerMensuel.toStringAsFixed(0);
    _charges.text = a.charges.toStringAsFixed(0);
    // Usage courant : deux mois de loyer en caution.
    _depot.text = (a.loyerMensuel * 2).toStringAsFixed(0);
  }

  /// Moment du dernier changement d'étape : les boutons de la barre changent
  /// de rôle sous le doigt (« Continuer » devient « Créer le bail »), un appui
  /// en double ne doit pas déclencher l'action de l'étape suivante.
  DateTime _changement = DateTime.now();

  bool get _appuiTropProche =>
      DateTime.now().difference(_changement) < const Duration(milliseconds: 600);

  /// Enveloppe une action de la barre pour ignorer l'appui qui suit de trop
  /// près un changement d'étape.
  VoidCallback? _garde(VoidCallback? action) =>
      action == null ? null : () => _appuiTropProche ? null : action();

  void _aller(_Etape etape) => setState(() {
        _etape = etape;
        _changement = DateTime.now();
      });

  void _precedent() {
    if (_etape.index > 0 && _bail == null) _aller(_Etape.values[_etape.index - 1]);
  }

  Future<void> _choisirAppartement() async {
    final repo = ref.read(appartementRepositoryProvider);
    final a = await Navigator.push<Appartement>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionPage<Appartement>(
          titre: 'Logement libre',
          hintRecherche: 'Référence, bien…',
          emptyMessage: 'Aucun logement libre.',
          fetcherPour: (r) =>
              (page, size) =>
                  repo.getPage(page: page, size: size, statut: StatutAppartement.libre, recherche: r),
          titreItem: (a) => a.libelleComplet,
          sousTitreItem: (a) => '${a.type.libelle} · ${formatMontant(a.montantMensuel)}/mois',
        ),
      ),
    );
    if (a == null) return;
    setState(() {
      _appartement = a;
      _reprendreConditions(a);
    });
  }

  Future<void> _choisirLocataire() async {
    final repo = ref.read(locataireRepositoryProvider);
    final l = await Navigator.push<Locataire>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectionPage<Locataire>(
          titre: 'Locataire',
          hintRecherche: 'Nom, téléphone…',
          fetcherPour: (r) =>
              (page, size) => repo.getPage(page: page, size: size, recherche: r),
          titreItem: (l) => l.nomComplet,
          sousTitreItem: (l) => l.telephone,
        ),
      ),
    );
    if (l != null) setState(() => _locataire = l);
  }

  Future<void> _signer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final bail = Bail(
      appartementId: _appartement!.id!,
      locataireId: _locataire!.id!,
      dateDebut: _dateDebut!,
      dateFin: _dateFin,
      loyerMensuel: parseMontantSaisi(_loyer.text),
      charges: parseMontantSaisi(_charges.text),
      depotGarantie: parseMontantSaisi(_depot.text),
      jourEcheance: int.tryParse(_jour.text),
    );
    final result = await ref.read(bailRepositoryProvider).create(bail);
    if (!mounted) return;
    setState(() => _envoi = false);
    result.fold((f) => showError(context, f.message), (b) {
      setState(() {
        _bail = b;
        _etape = _Etape.contrat;
        _changement = DateTime.now();
      });
    });
  }

  Future<void> _recharger() async {
    final result = await ref.read(bailRepositoryProvider).getById(_bail!.id!);
    if (!mounted) return;
    result.fold((_) {}, (b) => setState(() => _bail = b));
  }

  Future<void> _generer() async {
    setState(() => _generation = true);
    final ok = await ouvrirContratGenere(context, ref, _bail!);
    if (!mounted) return;
    setState(() => _generation = false);
    if (ok) _recharger();
  }

  Future<void> _chargerSigne() async {
    final maj = await chargerContratSigne(context, ref, _bail!);
    if (maj != null && mounted) setState(() => _bail = maj);
  }

  void _terminer() => Navigator.pop(context, _bail);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Une fois le bail créé, quitter renvoie le bail ; avant, le retour
      // système recule d'une étape.
      canPop: _bail != null || _etape.index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _precedent();
      },
      child: Scaffold(
        appBar: AppHeader(
          title: _bail == null ? 'Nouveau bail' : 'Bail ${_bail!.reference}',
          backOverride: _bail != null
              ? _terminer
              : _etape.index > 0
              ? _precedent
              : null,
        ),
        body: Column(
          children: [
            _Progression(etape: _etape),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: switch (_etape) {
                    _Etape.logement => _etapeLogement(),
                    _Etape.locataire => _etapeLocataire(),
                    _Etape.conditions => _etapeConditions(),
                    _Etape.contrat => _etapeContrat(),
                  },
                ),
              ),
            ),
            _BarreActions(children: _actions()),
          ],
        ),
      ),
    );
  }

  // ── Étapes ────────────────────────────────────────────────────────────────

  List<Widget> _etapeLogement() => [
    const _TitreEtape(titre: 'Quel logement ?', detail: 'Seuls les logements libres sont proposés.'),
    _CarteChoix(
      icone: _appartement?.type.icone ?? Icons.home_work_outlined,
      titre: _appartement?.libelleComplet,
      detail: _appartement == null
          ? null
          : '${_appartement!.type.libelle} · ${formatMontant(_appartement!.montantMensuel)} / mois',
      vide: 'Choisir un logement',
      actif: widget.appartementInitial == null,
      onTap: _choisirAppartement,
    ),
  ];

  List<Widget> _etapeLocataire() => [
    const _TitreEtape(titre: 'Quel locataire ?', detail: 'Il recevra le contrat à signer.'),
    _CarteChoix(
      icone: Icons.person_outline,
      initiales: _locataire?.initiales,
      titre: _locataire?.nomComplet,
      detail: _locataire?.telephone,
      vide: 'Choisir un locataire',
      actif: widget.locataireInitial == null,
      onTap: _choisirLocataire,
    ),
  ];

  List<Widget> _etapeConditions() => [
    const _TitreEtape(titre: 'Conditions du bail', detail: 'Reprises du logement, vous pouvez les ajuster.'),
    _Recap(appartement: _appartement!, locataire: _locataire!),
    const SizedBox(height: 12),
    GroupeChamps(
      titre: 'Durée',
      icone: Icons.event_outlined,
      couleur: AppColors.info,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ChampDate(
                label: 'Début',
                valeur: _dateDebut,
                obligatoire: true,
                onChanged: (d) => setState(() => _dateDebut = d),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChampDate(
                label: 'Fin',
                valeur: _dateFin,
                premiere: _dateDebut,
                onChanged: (d) => setState(() => _dateFin = d),
              ),
            ),
          ],
        ),
        kGapChamps,
        ChampEntier(
          controller: _jour,
          label: 'Jour d\'échéance du loyer',
          hint: '5',
          obligatoire: true,
          aide: 'Jour du mois où le loyer est exigible (1 à 28)',
          validator: (v) {
            final j = int.tryParse(v ?? '');
            return j == null || j < 1 || j > 28 ? 'Entre 1 et 28.' : null;
          },
        ),
      ],
    ),
    GroupeChamps(
      titre: 'Montants',
      icone: Icons.payments_outlined,
      couleur: AppColors.positive,
      children: [
        ChampMontant(controller: _loyer, label: 'Loyer mensuel', obligatoire: true, strictementPositif: true),
        kGapChamps,
        ChampMontant(controller: _charges, label: 'Charges mensuelles'),
        kGapChamps,
        ChampMontant(controller: _depot, label: 'Dépôt de garantie'),
      ],
    ),
  ];

  List<Widget> _etapeContrat() {
    final b = _bail!;
    final signe = b.statutContrat == StatutContrat.signe;
    return [
      const SizedBox(height: 8),
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.positive.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 34, color: AppColors.positive),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Bail créé',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark),
      ),
      const SizedBox(height: 4),
      Text(
        '${b.logement} · ${b.locataireNom ?? ''}\nà partir du ${formatDate(b.dateDebut)}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.label, height: 1.4),
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrat-${b.reference}.pdf',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Prérempli : parties, logement, loyer, caution, échéance',
                    style: TextStyle(fontSize: 12, color: AppColors.label),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _EtapeContrat(
        numero: 1,
        titre: 'Générer le contrat',
        detail: 'Aperçu, puis partage (WhatsApp, e-mail) ou impression',
        fait: b.statutContrat != StatutContrat.aGenerer,
      ),
      _EtapeContrat(
        numero: 2,
        titre: 'Faire signer le locataire',
        detail: 'Sur papier, avec la mention « Lu et approuvé »',
        fait: signe,
      ),
      _EtapeContrat(
        numero: 3,
        titre: 'Charger le contrat signé',
        detail: signe ? 'Archivé sur le bail' : 'Photo des pages ou PDF ; possible plus tard depuis le bail',
        fait: signe,
      ),
    ];
  }

  List<Widget> _actions() {
    switch (_etape) {
      case _Etape.logement:
        return [
          Expanded(
            child: BoutonPrincipal(
              label: 'Continuer',
              onPressed: _garde(_appartement == null ? null : () => _aller(_Etape.locataire)),
            ),
          ),
        ];
      case _Etape.locataire:
        return [
          _BoutonRetour(onPressed: _precedent),
          const SizedBox(width: 10),
          Expanded(
            child: BoutonPrincipal(
              label: 'Continuer',
              onPressed: _garde(_locataire == null ? null : () => _aller(_Etape.conditions)),
            ),
          ),
        ];
      case _Etape.conditions:
        return [
          _BoutonRetour(onPressed: _envoi ? null : _precedent),
          const SizedBox(width: 10),
          Expanded(
            child: BoutonPrincipal(
              label: 'Créer le bail',
              icon: Icons.draw_outlined,
              loading: _envoi,
              onPressed: _garde(_signer),
            ),
          ),
        ];
      case _Etape.contrat:
        final b = _bail!;
        if (b.statutContrat == StatutContrat.signe) {
          return [
            Expanded(
              child: BoutonPrincipal(label: 'Terminer', onPressed: _terminer),
            ),
          ];
        }
        return [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BoutonPrincipal(
                  label: b.statutContrat == StatutContrat.aGenerer
                      ? 'Générer le contrat PDF'
                      : 'Revoir et partager le contrat',
                  icon: Icons.picture_as_pdf_outlined,
                  loading: _generation,
                  onPressed: _garde(_generer),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: BoutonSecondaire(
                        label: 'Contrat signé',
                        icon: Icons.document_scanner_outlined,
                        onPressed: _garde(_chargerSigne),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BoutonSecondaire(label: 'Plus tard', onPressed: _garde(_terminer)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
    }
  }
}

// ── Éléments de l'assistant ─────────────────────────────────────────────────

/// Barre de progression en quatre segments, libellé de l'étape en cours.
class _Progression extends StatelessWidget {
  final _Etape etape;

  const _Progression({required this.etape});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final e in _Etape.values) ...[
                if (e.index > 0) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    decoration: BoxDecoration(
                      color: e.index <= etape.index ? AppColors.primary : AppColors.grey200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${etape.index + 1} sur ${_Etape.values.length} · ${etape.libelle}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.label),
          ),
        ],
      ),
    );
  }
}

class _TitreEtape extends StatelessWidget {
  final String titre;
  final String detail;

  const _TitreEtape({required this.titre, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(fontSize: 13, color: AppColors.label)),
        ],
      ),
    );
  }
}

/// Grande carte de sélection : vide, elle invite à choisir ; remplie, elle
/// montre le choix et propose de le changer.
class _CarteChoix extends StatelessWidget {
  final IconData icone;
  final String? initiales;
  final String? titre;
  final String? detail;
  final String vide;
  final bool actif;
  final VoidCallback onTap;

  const _CarteChoix({
    required this.icone,
    this.initiales,
    required this.titre,
    required this.detail,
    required this.vide,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final choisi = titre != null;
    return Material(
      color: choisi ? AppColors.cardTint : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: actif ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: choisi ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
              width: choisi ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                child: initiales != null
                    ? Text(
                        initiales!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : Icon(choisi ? icone : Icons.add_rounded, color: AppColors.primaryDark, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre ?? vide,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: choisi ? AppColors.dark : AppColors.primaryDark,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 3),
                      Text(detail!, style: TextStyle(fontSize: 12.5, color: AppColors.label)),
                    ],
                  ],
                ),
              ),
              if (actif)
                Text(
                  choisi ? 'Changer' : '',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rappel du logement et du locataire choisis, au-dessus des conditions.
class _Recap extends StatelessWidget {
  final Appartement appartement;
  final Locataire locataire;

  const _Recap({required this.appartement, required this.locataire});

  @override
  Widget build(BuildContext context) {
    Widget ligne(IconData icone, String texte) => Row(
      children: [
        Icon(icone, size: 16, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ligne(appartement.type.icone, '${appartement.libelleComplet} · ${appartement.type.libelle}'),
          const SizedBox(height: 8),
          ligne(Icons.person_outline, locataire.nomComplet),
        ],
      ),
    );
  }
}

class _EtapeContrat extends StatelessWidget {
  final int numero;
  final String titre;
  final String detail;
  final bool fait;

  const _EtapeContrat({required this.numero, required this.titre, required this.detail, required this.fait});

  @override
  Widget build(BuildContext context) {
    final couleur = fait ? AppColors.positive : AppColors.primaryDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: fait
                ? Icon(Icons.check_rounded, size: 16, color: couleur)
                : Text(
                    '$numero',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: couleur),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.dark),
                ),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(fontSize: 12, color: AppColors.label)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre d'actions collée en bas de l'assistant.
class _BarreActions extends StatelessWidget {
  final List<Widget> children;

  const _BarreActions({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: children),
        ),
      ),
    );
  }
}

class _BoutonRetour extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BoutonRetour({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Icon(Icons.arrow_back_rounded, color: AppColors.dark),
      ),
    );
  }
}
