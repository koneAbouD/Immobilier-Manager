import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/debounce.dart';
import '../../../../core/widgets/dialogs.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/libelle_bouton.dart';
import '../../../../core/widgets/liste_carte.dart';
import '../../../../core/widgets/paged_list_view.dart';
import '../../../../core/widgets/statut_filtre_chip.dart';
import '../../../appartement/presentation/pages/appartement_detail_page.dart';
import '../../../immeuble/presentation/pages/immeuble_detail_page.dart';
import '../../../locataire/presentation/pages/locataire_detail_page.dart';
import '../../../maintenance/presentation/pages/maintenance_detail_page.dart';
import '../../domain/entities/entree_journal.dart';
import '../providers/journal_providers.dart';

final _heure = DateFormat('HH:mm', 'fr_FR');
final _jour = DateFormat('EEEE d MMMM', 'fr_FR');
final _jourAnnee = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

String _majuscule(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

DateTime _sansHeure(DateTime d) => DateTime(d.year, d.month, d.day);

/// « Aujourd'hui », « Hier », « Mardi 18 novembre » (avec l'année si elle diffère).
String libelleJour(DateTime date, {DateTime? maintenant}) {
  final aujourdHui = _sansHeure(maintenant ?? DateTime.now());
  final jour = _sansHeure(date);
  final ecart = aujourdHui.difference(jour).inDays;
  if (ecart == 0) return 'Aujourd\'hui';
  if (ecart == 1) return 'Hier';
  return _majuscule((jour.year == aujourdHui.year ? _jour : _jourAnnee).format(jour));
}

/// Journal des modifications et suppressions de l'organisation (biens,
/// locaux, locataires, travaux), réservé aux administrateurs : du plus
/// récent au plus ancien, groupé par jour, filtrable par type et par action.
class JournalActionsPage extends ConsumerStatefulWidget {
  const JournalActionsPage({super.key});

  @override
  ConsumerState<JournalActionsPage> createState() => _JournalActionsPageState();
}

class _JournalActionsPageState extends ConsumerState<JournalActionsPage> {
  final _debounce = Debouncer();
  String _recherche = '';
  TypeEntiteJournal? _type;
  ActionJournal? _action;

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  void _ouvrirDetail(EntreeJournal e) {
    afficherFeuille<void>(context, builder: (_) => _FeuilleEntree(entree: e, onOuvrirFiche: _ouvrirFiche));
  }

  void _ouvrirFiche(EntreeJournal e) {
    final id = e.entiteId;
    if (id == null) return;
    final page = switch (e.type) {
      TypeEntiteJournal.bien => ImmeubleDetailPage(immeubleId: id),
      TypeEntiteJournal.local => AppartementDetailPage(appartementId: id),
      TypeEntiteJournal.locataire => LocataireDetailPage(locataireId: id),
      TypeEntiteJournal.travaux => MaintenanceDetailPage(maintenanceId: id),
    } as Widget;
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(journalRepositoryProvider);
    return Scaffold(
      appBar: const AppHeader(title: 'Journal des actions'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ChampRecherche(
              hint: 'Nom, bien, auteur…',
              onChanged: (v) => _debounce.run(() => setState(() => _recherche = v.trim())),
            ),
          ),
          FiltresStatut<TypeEntiteJournal?>(
            options: [null, ...TypeEntiteJournal.values],
            selection: _type,
            libelle: (t) => t?.pluriel ?? 'Tout',
            onSelected: (t) => setState(() => _type = t),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: _SelecteurAction(
              selection: _action,
              onSelected: (a) => setState(() => _action = a),
            ),
          ),
          Expanded(
            child: PagedListView<EntreeJournal>(
              filtresKey: (_recherche, _type, _action),
              fetcher: (page, size) => repo.getPage(
                  page: page, size: size, type: _type, action: _action, recherche: _recherche),
              emptyIcon: Icons.history_rounded,
              emptyMessage: _recherche.isEmpty && _type == null && _action == null
                  ? 'Aucune modification ni suppression pour l\'instant.\n'
                      'Chaque changement sur un bien, un local, un locataire '
                      'ou des travaux apparaîtra ici.'
                  : 'Aucune action ne correspond à ces critères.',
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              enTete: (precedent, courant) =>
                  precedent != null && _sansHeure(precedent.date) == _sansHeure(courant.date)
                      ? null
                      : _EnteteJour(courant.date),
              itemBuilder: (context, e) => _CarteEntree(entree: e, onTap: () => _ouvrirDetail(e)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Choix de l'action : toutes, modifications ou suppressions.
class _SelecteurAction extends StatelessWidget {
  final ActionJournal? selection;
  final ValueChanged<ActionJournal?> onSelected;

  const _SelecteurAction({required this.selection, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = <ActionJournal?>[null, ...ActionJournal.values];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(o),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: o == selection ? AppColors.blanc : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: o == selection
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (o != null) ...[
                        Icon(o.icone, size: 14, color: o == selection ? o.couleur : AppColors.grey500),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          o?.pluriel ?? 'Toutes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: o == selection ? FontWeight.w700 : FontWeight.w500,
                            color: o == selection ? AppColors.dark : AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EnteteJour extends StatelessWidget {
  final DateTime date;

  const _EnteteJour(this.date);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Row(
        children: [
          Text(libelleJour(date),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: AppColors.grey200, height: 1)),
        ],
      ),
    );
  }
}

/// Tuile d'une entrée : la donnée et son type, l'action, un aperçu du premier
/// changement, l'auteur et l'heure.
class _CarteEntree extends StatelessWidget {
  final EntreeJournal entree;
  final VoidCallback onTap;

  const _CarteEntree({required this.entree, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = entree;
    final teinte = e.type.couleur;
    final premier = e.changements.isEmpty ? null : e.changements.first;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconeEntree(type: e.type, action: e.action),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(e.libelle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                          ),
                          const SizedBox(width: 8),
                          PastilleStatut(e.action.libelle, e.action.couleur),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [e.type.libelle, if (e.contexte != null && e.contexte!.isNotEmpty) e.contexte].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: teinte, fontWeight: FontWeight.w600),
                      ),
                      if (!e.estSuppression && premier != null) ...[
                        const SizedBox(height: 6),
                        _ApercuChangement(premier, autres: e.changements.length - 1),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Avatar(e.auteur),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(e.auteur,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: AppColors.grey600, fontWeight: FontWeight.w500)),
                          ),
                          Icon(Icons.schedule_rounded, size: 12, color: AppColors.grey400),
                          const SizedBox(width: 3),
                          Text(_heure.format(e.date), style: TextStyle(fontSize: 11.5, color: AppColors.grey500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tuile du type de donnée, marquée en coin de l'action.
class _IconeEntree extends StatelessWidget {
  final TypeEntiteJournal type;
  final ActionJournal action;

  const _IconeEntree({required this.type, required this.action});

  static const taille = 42.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: taille + 4,
      height: taille + 4,
      child: Stack(
        children: [
          Container(
            width: taille,
            height: taille,
            decoration: BoxDecoration(
              color: type.couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(type.icone, color: type.couleur, size: taille * 0.5),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: action.couleur,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blanc, width: 2),
              ),
              child: Icon(action.icone, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApercuChangement extends StatelessWidget {
  final Changement changement;
  final int autres;

  const _ApercuChangement(this.changement, {required this.autres});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 12, color: AppColors.grey600);
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '${changement.champ} : ', style: style.copyWith(fontWeight: FontWeight.w600)),
              TextSpan(
                text: changement.avant ?? '—',
                style: style.copyWith(decoration: TextDecoration.lineThrough, color: AppColors.grey400),
              ),
              TextSpan(text: '  →  ', style: style),
              TextSpan(
                text: changement.apres ?? '—',
                style: style.copyWith(color: AppColors.dark, fontWeight: FontWeight.w600),
              ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (autres > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
            child: Text('+$autres',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.grey600)),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nom;

  const _Avatar(this.nom);

  @override
  Widget build(BuildContext context) {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    final initiales = mots.isEmpty
        ? '?'
        : (mots.first.characters.first + (mots.length > 1 ? mots.last.characters.first : '')).toUpperCase();
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Text(initiales, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
    );
  }
}

/// Détail d'une entrée : qui, quand, et chaque champ avant → après (ou les
/// dernières valeurs d'une donnée supprimée).
class _FeuilleEntree extends StatelessWidget {
  final EntreeJournal entree;
  final ValueChanged<EntreeJournal> onOuvrirFiche;

  const _FeuilleEntree({required this.entree, required this.onOuvrirFiche});

  @override
  Widget build(BuildContext context) {
    final e = entree;
    final quand = '${libelleJour(e.date)} à ${_heure.format(e.date)}';
    final n = e.changements.length;
    final titreSection = e.estSuppression
        ? 'Valeurs au moment de la suppression'
        : '$n champ${n > 1 ? 's' : ''} modifié${n > 1 ? 's' : ''}';
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        children: [
          EnteteFeuille(
            icone: e.type.icone,
            titre: e.libelle,
            sousTitre: '${e.type.libelle} ${e.action.participe}',
            couleur: e.action.couleur,
          ),
          const SizedBox(height: 14),
          _LigneInfo(Icons.person_outline_rounded, 'Par', e.auteur),
          _LigneInfo(Icons.event_outlined, 'Le', quand),
          if (e.contexte != null && e.contexte!.isNotEmpty)
            _LigneInfo(e.type == TypeEntiteJournal.travaux ? Icons.place_outlined : Icons.apartment_rounded,
                e.type == TypeEntiteJournal.travaux ? 'Lieu' : 'Bien', e.contexte!),
          const SizedBox(height: 14),
          Text(titreSection.toUpperCase(),
              style: TextStyle(
                  fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w800, color: AppColors.grey500)),
          const SizedBox(height: 8),
          if (e.changements.isEmpty)
            Text('Aucun détail enregistré.', style: TextStyle(fontSize: 13, color: AppColors.grey500))
          else
            for (final c in e.changements) _LigneChangement(c, suppression: e.estSuppression),
          if (!e.estSuppression && e.entiteId != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(context);
                onOuvrirFiche(e);
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: LibelleBouton(switch (e.type) {
                TypeEntiteJournal.bien => 'Ouvrir la fiche du bien',
                TypeEntiteJournal.local => 'Ouvrir la fiche du local',
                TypeEntiteJournal.locataire => 'Ouvrir la fiche du locataire',
                TypeEntiteJournal.travaux => 'Ouvrir la fiche des travaux',
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;

  const _LigneInfo(this.icone, this.label, this.valeur);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icone, size: 16, color: AppColors.grey500),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.grey500)),
          ),
          Expanded(
            child: Text(valeur,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
          ),
        ],
      ),
    );
  }
}

class _LigneChangement extends StatelessWidget {
  final Changement changement;
  final bool suppression;

  const _LigneChangement(this.changement, {required this.suppression});

  @override
  Widget build(BuildContext context) {
    final c = changement;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.champ, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.grey600)),
          const SizedBox(height: 6),
          if (suppression)
            Text(c.avant ?? '—', style: TextStyle(fontSize: 13.5, color: AppColors.dark))
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _Valeur(c.avant, ancienne: true),
                Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.grey400),
                _Valeur(c.apres, ancienne: false),
              ],
            ),
        ],
      ),
    );
  }
}

class _Valeur extends StatelessWidget {
  final String? texte;
  final bool ancienne;

  const _Valeur(this.texte, {required this.ancienne});

  @override
  Widget build(BuildContext context) {
    final vide = texte == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ancienne ? AppColors.errorTint : AppColors.positiveTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        vide ? 'Non renseigné' : texte!,
        style: TextStyle(
          fontSize: 13,
          fontStyle: vide ? FontStyle.italic : FontStyle.normal,
          fontWeight: ancienne ? FontWeight.w500 : FontWeight.w700,
          color: ancienne ? AppColors.grey600 : AppColors.positive,
          decoration: ancienne && !vide ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}
