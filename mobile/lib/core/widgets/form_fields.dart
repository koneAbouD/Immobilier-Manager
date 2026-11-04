import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Espacement standard entre champs de formulaire.
const kGapChamps = SizedBox(height: 14);

/// Champ texte obligatoire ou facultatif.
class ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obligatoire;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const ChampTexte({
    super.key,
    required this.controller,
    required this.label,
    this.obligatoire = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: obligatoire ? '$label *' : label),
      validator: validator ??
          (obligatoire
              ? (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire.' : null
              : null),
    );
  }
}

/// Champ montant en FCFA (chiffres uniquement).
class ChampMontant extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obligatoire;
  final bool strictementPositif;

  const ChampMontant({
    super.key,
    required this.controller,
    required this.label,
    this.obligatoire = false,
    this.strictementPositif = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
      decoration: InputDecoration(
        labelText: obligatoire ? '$label *' : label,
        suffixText: 'FCFA',
      ),
      validator: (v) {
        final montant = parseMontantSaisi(v);
        if (montant == null) return obligatoire ? 'Champ obligatoire.' : null;
        if (strictementPositif && montant <= 0) return 'Le montant doit être positif.';
        return null;
      },
    );
  }
}

/// Champ entier facultatif.
class ChampEntier extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const ChampEntier({super.key, required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}

/// Sélecteur de date en lecture seule (ouvre le calendrier au tap).
class ChampDate extends StatelessWidget {
  final String label;
  final DateTime? valeur;
  final ValueChanged<DateTime?> onChanged;
  final bool obligatoire;
  final DateTime? premiere;
  final DateTime? derniere;

  const ChampDate({
    super.key,
    required this.label,
    required this.valeur,
    required this.onChanged,
    this.obligatoire = false,
    this.premiere,
    this.derniere,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: valeur,
      validator: (_) => obligatoire && valeur == null ? 'Champ obligatoire.' : null,
      builder: (state) => InkWell(
        onTap: () async {
          final choisie = await showDatePicker(
            context: context,
            initialDate: valeur ?? DateTime.now(),
            firstDate: premiere ?? DateTime(2000),
            lastDate: derniere ?? DateTime(2100),
          );
          if (choisie != null) {
            onChanged(choisie);
            state.didChange(choisie);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: obligatoire ? '$label *' : label,
            errorText: state.errorText,
            suffixIcon: valeur != null && !obligatoire
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      onChanged(null);
                      state.didChange(null);
                    },
                  )
                : const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(valeur == null ? '' : formatDate(valeur)),
        ),
      ),
    );
  }
}

/// Liste déroulante sur une énumération (ou toute liste de valeurs).
class ChampChoix<T> extends StatelessWidget {
  final String label;
  final T? valeur;
  final List<T> options;
  final String Function(T) libelle;
  final ValueChanged<T?> onChanged;
  final bool obligatoire;

  const ChampChoix({
    super.key,
    required this.label,
    required this.valeur,
    required this.options,
    required this.libelle,
    required this.onChanged,
    this.obligatoire = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: valeur,
      isExpanded: true,
      decoration: InputDecoration(labelText: obligatoire ? '$label *' : label),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(libelle(o))))
          .toList(),
      onChanged: onChanged,
      validator: (v) => obligatoire && v == null ? 'Champ obligatoire.' : null,
    );
  }
}

/// Barre de recherche des listes, suivie d'un bouton d'ajout facultatif : la
/// ligne « recherche + » de la Flotte de VTC Manager, qui remplace le bouton
/// flottant.
class ChampRecherche extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  /// Bouton « + » carré à droite de la barre.
  final VoidCallback? onAjouter;
  final String ajouterTooltip;

  const ChampRecherche({
    super.key,
    required this.hint,
    required this.onChanged,
    this.onAjouter,
    this.ajouterTooltip = 'Ajouter',
  });

  @override
  State<ChampRecherche> createState() => _ChampRechercheState();
}

class _ChampRechercheState extends State<ChampRecherche> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    OutlineInputBorder bord(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    final barre = SizedBox(
      height: 46,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) => TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 14, color: AppColors.dark),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.grey400),
            prefixIcon: Icon(Icons.search_rounded,
                size: 18,
                color: value.text.isNotEmpty ? primary : AppColors.grey400),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 16, color: AppColors.grey400),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  ),
            filled: true,
            fillColor: AppColors.blanc,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            border: bord(AppColors.grey200),
            enabledBorder: bord(AppColors.grey200),
            focusedBorder: bord(primary, 1.5),
          ),
        ),
      ),
    );
    if (widget.onAjouter == null) return barre;
    return Row(children: [
      Expanded(child: barre),
      const SizedBox(width: 8),
      BoutonAjout(onTap: widget.onAjouter!, tooltip: widget.ajouterTooltip),
    ]);
  }
}

/// Bouton « + » carré, blanc bordé de gris, qui se fond dans la barre de
/// recherche.
class BoutonAjout extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;

  const BoutonAjout({super.key, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.blanc,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.grey200),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            height: 46,
            width: 46,
            child: Icon(Icons.add_rounded, size: 22, color: AppColors.grey600),
          ),
        ),
      ),
    );
  }
}

/// Bouton principal des formulaires : pleine largeur, 50 px, indicateur de
/// chargement à la place du libellé pendant l'envoi.
class BoutonPrincipal extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  /// Rouge d'erreur (résiliation, annulation).
  final bool destructive;

  const BoutonPrincipal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final contenu = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]);
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: destructive ? AppColors.error : null,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: contenu,
      ),
    );
  }
}

/// Bouton secondaire : contour gris, texte foncé (ou rouge si [destructive]).
class BoutonSecondaire extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool destructive;

  const BoutonSecondaire({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = destructive ? AppColors.error : AppColors.dark;
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: couleur,
          backgroundColor: AppColors.blanc,
          side: BorderSide(
              color: destructive
                  ? AppColors.error.withValues(alpha: 0.4)
                  : AppColors.border),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Ligne « libellé : valeur » sans icône (feuilles, résumés).
class LigneInfo extends StatelessWidget {
  final String label;
  final String? valeur;
  final bool fort;

  const LigneInfo(this.label, this.valeur, {super.key, this.fort = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: AppColors.label)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valeur == null || valeur!.isEmpty ? '—' : valeur!,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: fort ? 14 : 13,
                  fontWeight: fort ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Groupe de champs d'un formulaire, posé sur une carte : un titre discret
/// au-dessus, comme les rubriques des formulaires de VTC Manager.
class GroupeChamps extends StatelessWidget {
  final String titre;
  final List<Widget> children;

  const GroupeChamps({super.key, required this.titre, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(titre.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.label)),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
