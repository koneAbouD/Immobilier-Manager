import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/droits.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';
import 'dialogs.dart';

/// En-tête standard de toutes les pages.
///
/// Implémente [PreferredSizeWidget] → s'utilise directement en `appBar:`
/// sans aucun wrapper [PreferredSize] ni [SafeArea].
///
/// ```dart
/// // Cas minimal
/// appBar: const AppHeader(title: 'Ma page'),
///
/// // Avec action icône
/// appBar: AppHeader(
///   title: 'Ma page',
///   action: AppHeaderAction(icon: Icons.add_rounded, onTap: _add),
/// ),
///
/// // Sans bouton retour (écran racine)
/// appBar: AppHeader(title: '', showBack: false, action: ...),
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Masque le bouton retour (ex. : écrans racines sans navigation parent).
  final bool showBack;

  /// Surcharge du comportement du bouton retour.
  final VoidCallback? backOverride;

  /// Widget affiché à droite. Sa largeur est libre : le titre reste centré sur
  /// la barre quoi qu'il arrive.
  final Widget? action;

  /// Widget affiché à gauche sur les écrans racines (ex. : bouton menu de
  /// l'accueil). Ignoré quand [showBack] est true, le bouton retour occupant
  /// déjà cette place.
  final Widget? leading;

  /// Pill colorée affichée sous le titre (ex. : "Sélection").
  final String? badge;

  /// Contenu centré à la place du titre (ex. : pastilles d'onglets de la
  /// Flotte). Occupe la place laissée libre par [leading] et [action] ;
  /// [title] et [badge] sont alors ignorés.
  final Widget? center;

  /// Couleur de fond (blanc par défaut).
  final Color? backgroundColor;

  /// Fond du bouton retour ([AppColors.headerButton] par défaut). À surcharger
  /// quand l'en-tête est posé sur une teinte proche, où la pastille se
  /// confondrait avec le fond.
  final Color? backButtonColor;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.backOverride,
    this.action,
    this.badge,
    this.backgroundColor,
    this.backButtonColor,
    this.leading,
    this.center,
  });

  /// Padding vertical de la barre, en haut comme en bas.
  static const double _paddingVertical = 14;

  /// Hauteur du contenu, paddings exclus : celle du bouton retour.
  static const double _hauteurContenu = 38;

  /// Hauteur du contenu avec badge : le titre (~24) et la pilule (~20)
  /// s'empilent, séparés de 4. Sans ce supplément, la colonne déborde de
  /// l'en-tête ("RenderFlex overflowed on the bottom").
  static const double _hauteurContenuBadge = 62;

  /// Hauteur du contenu selon la présence du badge.
  double get _hauteurContenuEffective =>
      badge == null ? _hauteurContenu : _hauteurContenuBadge;

  @override
  Size get preferredSize =>
      Size.fromHeight(_hauteurContenuEffective + _paddingVertical * 2);

  @override
  Widget build(BuildContext context) {
    final backBtn = showBack
        ? GestureDetector(
            onTap: backOverride ?? () => Navigator.of(context).pop(),
            child: Container(
              width: 56,
              height: 38,
              decoration: BoxDecoration(
                color: backButtonColor ?? AppColors.headerButton,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 18, color: AppColors.dark),
            ),
          )
        : null;

    final titleColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
              letterSpacing: -0.3,
            ),
          ),
        if (badge != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );

    // Le titre est centré sur la barre, et non dans la place que lui laissent
    // ses voisins : une action large (filtre, bouton « Modifier ») ne le
    // décale donc plus. [NavigationToolbar] — la mécanique interne d'[AppBar] —
    // s'en charge, et le repousse de lui-même le jour où le titre et une
    // action se disputeraient la même place.
    // Hauteur imposée : la toolbar cherche à remplir ce qu'on lui donne, et
    // [AppHeader] ne sert pas qu'en `appBar:` — posé dans le corps d'une page
    // (bandeau de profil des réglages), il reçoit une hauteur illimitée et
    // s'étirerait à l'infini.
    final row = SizedBox(
      height: _hauteurContenuEffective,
      child: NavigationToolbar(
        leading: showBack ? backBtn : leading,
        middle: center ?? titleColumn,
        trailing: action,
        centerMiddle: true,
        // Les pastilles d'onglets occupent toute la ligne : sans marge propre,
        // elles colleraient un bouton latéral quand il y en a un.
        middleSpacing: center != null ? 4 : 8,
      ),
    );

    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: _paddingVertical),
          child: row,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Bouton d'action ovale standard (même style que le bouton retour).
///
/// Supporte trois variantes :
/// - **icône** : [icon] seul → bouton ovale avec icône
/// - **texte** : [label] seul → bouton ovale avec texte "Modifier" etc.
/// - **chargement** : [loading] = true → indicateur circulaire à la place
class AppHeaderAction extends StatelessWidget {
  final VoidCallback? onTap;

  /// Icône affichée (mutuellement exclusif avec [label]).
  final IconData? icon;

  /// Taille de l'icône (20 par défaut).
  final double iconSize;

  /// Texte affiché à la place d'une icône (ex. : "Modifier").
  final String? label;

  /// Affiche un indicateur de chargement à la place de l'icône/texte.
  final bool loading;

  const AppHeaderAction({
    super.key,
    this.onTap,
    this.icon,
    this.iconSize = 20,
    this.label,
    this.loading = false,
  }) : assert(
          icon != null || label != null || loading,
          'AppHeaderAction requires icon, label, or loading:true',
        );

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.dark,
        ),
      );
    } else if (label != null) {
      child = Text(
        label!,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      );
    } else {
      child = Icon(icon, size: iconSize, color: AppColors.dark);
    }

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 38,
        // Largeur fixe pour icône, padding horizontal pour texte
        width: label != null ? null : 56,
        padding:
            label != null ? const EdgeInsets.symmetric(horizontal: 14) : null,
        decoration: BoxDecoration(
          color: AppColors.headerButton,
          borderRadius: BorderRadius.circular(20),
        ),
        // `widthFactor: 1` : le bouton se règle sur son contenu. Un [Center]
        // nu s'étirerait à toute la largeur offerte — sans conséquence dans une
        // Row, mais la barre borne désormais ses côtés pour centrer le titre,
        // et le bouton « Modifier » s'étalait alors sur tout l'en-tête.
        child: Align(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}

/// Actions d'en-tête des pages de détail : menu « ⋯ » (suppression), puis
/// « Modifier ».
///
/// Chaque action ne paraît que si le rôle la permet ([Droits]) : « Modifier »
/// demande [ActionMetier.ecrire], la suppression [droitSuppression]. Le menu
/// demande au serveur, à l'ouverture, si l'état de la donnée (bail,
/// historique…) autorise la suppression : sinon il la grise et dit pourquoi,
/// au lieu d'échouer après confirmation.
class ActionsDetail extends StatelessWidget {
  final VoidCallback? onModifier;
  final VoidCallback? onSupprimer;

  /// Rôle requis pour supprimer, selon la matrice des droits.
  final ActionMetier droitSuppression;

  /// Ressource dont le serveur expose `GET <ressource>/suppression`
  /// (ex. `/immeubles/12`) ; sans elle, la suppression n'est pas pré-vérifiée.
  final String? ressource;

  /// Action supplémentaire placée en tête (ex. appeler un locataire).
  final AppHeaderAction? extra;

  const ActionsDetail({
    super.key,
    this.onModifier,
    this.onSupprimer,
    this.droitSuppression = ActionMetier.ecrire,
    this.ressource,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    // Lecteur ou abonnement en lecture seule : la fiche se consulte seulement.
    final onSupprimer = Droits.peut(context, droitSuppression) ? this.onSupprimer : null;
    final onModifier = Droits.ecriture(context) ? this.onModifier : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (extra != null) ...[extra!, const SizedBox(width: 6)],
        if (onSupprimer != null)
          Tooltip(
            message: 'Plus d\'actions',
            child: AppHeaderAction(
              icon: Icons.more_horiz_rounded,
              onTap: () async {
                final supprimer = await afficherFeuille<bool>(context,
                    builder: (_) => _FeuilleActions(ressource: ressource));
                if (supprimer == true) onSupprimer();
              },
            ),
          ),
        if (onSupprimer != null && onModifier != null) const SizedBox(width: 6),
        if (onModifier != null)
          AppHeaderAction(label: 'Modifier', onTap: onModifier),
      ],
    );
  }
}

/// Feuille du menu « ⋯ » : « Supprimer », grisé avec son motif quand l'état
/// de la donnée l'interdit. Renvoie `true` pour lancer la suppression.
class _FeuilleActions extends ConsumerStatefulWidget {
  final String? ressource;

  const _FeuilleActions({this.ressource});

  @override
  ConsumerState<_FeuilleActions> createState() => _FeuilleActionsState();
}

class _FeuilleActionsState extends ConsumerState<_FeuilleActions> {
  /// Motif du refus, nul si la suppression est possible.
  String? _blocage;
  bool _verification = false;

  @override
  void initState() {
    super.initState();
    final ressource = widget.ressource;
    if (ressource == null) return;
    _verification = true;
    ref.read(apiClientProvider).get('$ressource/suppression').then((r) {
      if (!mounted) return;
      final etat = r is Map<String, dynamic> ? r : const <String, dynamic>{};
      setState(() {
        _verification = false;
        _blocage = etat['possible'] == false
            ? etat['motif'] as String? ?? 'Cet élément ne peut pas être supprimé.'
            : null;
      });
    }, onError: (_) {
      // Vérification impossible (réseau) : on laisse tenter, le serveur
      // refusera s'il le faut, avec son motif.
      if (mounted) setState(() => _verification = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloque = _blocage != null;
    final couleur = bloque ? AppColors.hint : AppColors.error;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        enabled: !bloque && !_verification,
        leading: _verification
            ? const SizedBox(width: 24, height: 24, child: Padding(
                padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2)))
            : Icon(Icons.delete_outline_rounded, color: couleur),
        title: Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700, color: couleur)),
        subtitle: bloque ? Text(_blocage!) : null,
        onTap: () => Navigator.pop(context, true),
      ),
      const SizedBox(height: 8),
    ]);
  }
}
