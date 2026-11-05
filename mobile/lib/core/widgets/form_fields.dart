import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'date_filter_dialogs.dart';
import 'premium_select_field.dart';

/// Espacement standard entre champs de formulaire.
const kGapChamps = SizedBox(height: 14);

/// Étiquette posée au-dessus d'un champ, au style des formulaires de VTC
/// Manager : petit libellé gris, astérisque rouge si le champ est obligatoire.
class EtiquetteChamp extends StatelessWidget {
  final String label;
  final bool obligatoire;

  const EtiquetteChamp(this.label, {super.key, this.obligatoire = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.label);
    return Text.rich(TextSpan(text: label, style: style, children: [
      if (obligatoire)
        TextSpan(
            text: ' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
    ]));
  }
}

/// Champ précédé de son étiquette.
class ChampEtiquete extends StatelessWidget {
  final String label;
  final bool obligatoire;
  final Widget child;

  const ChampEtiquete({super.key, required this.label, required this.child, this.obligatoire = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EtiquetteChamp(label, obligatoire: obligatoire),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Décoration « pilule » des champs : fond gris sans contour, indication en
/// gris dans le champ ; le contour d'accent au focus vient du thème.
InputDecoration decorationPilule({String? hint, Widget? suffixIcon, String? suffixText, String? aide}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.hint, fontSize: 15),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: TextStyle(color: AppColors.hint, fontSize: 13, fontWeight: FontWeight.w600),
      helperText: aide,
      helperStyle: TextStyle(fontSize: 11.5, color: AppColors.hint),
      helperMaxLines: 2,
    );

TextStyle get _styleSaisie => TextStyle(fontSize: 15, color: AppColors.dark);

/// Champ texte obligatoire ou facultatif.
class ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obligatoire;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const ChampTexte({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obligatoire = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ChampEtiquete(
      label: label,
      obligatoire: obligatoire,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: _styleSaisie,
        decoration: decorationPilule(hint: hint ?? label),
        validator: validator ??
            (obligatoire ? (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire.' : null : null),
      ),
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
    return ChampEtiquete(
      label: label,
      obligatoire: obligatoire,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
        style: _styleSaisie,
        decoration: decorationPilule(hint: '0', suffixText: 'FCFA'),
        validator: (v) {
          final montant = parseMontantSaisi(v);
          if (montant == null) return obligatoire ? 'Champ obligatoire.' : null;
          if (strictementPositif && montant <= 0) return 'Le montant doit être positif.';
          return null;
        },
      ),
    );
  }
}

/// Champ entier.
class ChampEntier extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obligatoire;

  /// Texte d'aide sous le champ.
  final String? aide;
  final String? Function(String?)? validator;

  const ChampEntier({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obligatoire = false,
    this.aide,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ChampEtiquete(
      label: label,
      obligatoire: obligatoire,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: _styleSaisie,
        decoration: decorationPilule(hint: hint ?? '0', aide: aide),
        validator: validator ??
            (obligatoire ? (v) => v == null || v.trim().isEmpty ? 'Champ obligatoire.' : null : null),
      ),
    );
  }
}

/// Fond « pilule » d'un champ qui s'ouvre au tap (date, sélection) : même
/// gabarit que les champs texte, contour rouge seulement en erreur.
class PiluleCliquable extends StatelessWidget {
  final String? valeur;
  final String hint;
  final Widget? prefixe;
  final Widget suffixe;
  final bool erreur;
  final bool actif;
  final VoidCallback onTap;

  const PiluleCliquable({
    super.key,
    required this.valeur,
    required this.hint,
    required this.suffixe,
    required this.onTap,
    this.prefixe,
    this.erreur = false,
    this.actif = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: actif ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: actif ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: erreur ? AppColors.error : Colors.transparent, width: erreur ? 1.4 : 1),
            ),
            child: Row(children: [
              if (prefixe != null) ...[prefixe!, const SizedBox(width: 10)],
              Expanded(
                child: Text(
                  valeur ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: valeur != null ? AppColors.dark : AppColors.hint,
                    fontWeight: valeur != null ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              suffixe,
            ]),
          ),
        ),
      ),
    );
  }
}

/// Message d'erreur sous un champ cliquable.
class ErreurChamp extends StatelessWidget {
  final String? message;

  const ErreurChamp(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(message!, style: TextStyle(color: AppColors.error, fontSize: 12)),
    );
  }
}

/// Sélecteur de date (ouvre le calendrier au tap).
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
      builder: (state) => ChampEtiquete(
        label: label,
        obligatoire: obligatoire,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PiluleCliquable(
            valeur: valeur == null ? null : formatDate(valeur),
            hint: 'jj/mm/aaaa',
            erreur: state.hasError,
            onTap: () async {
              FocusScope.of(context).unfocus();
              // Molette en feuille du bas, comme dans VTC Manager : la date
              // retenue est appliquée à la fermeture de la feuille.
              final choisie = await showDialog<DateTime>(
                context: context,
                builder: (_) => SingleDatePickerDialog(
                  initialDate: valeur ?? DateTime.now(),
                  firstDate: premiere ?? DateTime(1900),
                  lastDate: derniere ?? DateTime(2100),
                  titre: label,
                ),
              );
              if (choisie != null) {
                onChanged(choisie);
                state.didChange(choisie);
              }
            },
            suffixe: valeur != null && !obligatoire
                ? IconButton(
                    tooltip: 'Effacer',
                    icon: Icon(Icons.close_rounded, size: 18, color: AppColors.hint),
                    onPressed: () {
                      onChanged(null);
                      state.didChange(null);
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.hint),
                  ),
          ),
          ErreurChamp(state.errorText),
        ]),
      ),
    );
  }
}

/// Choix parmi une liste de valeurs : feuille de sélection « premium » de VTC
/// Manager à la place du menu déroulant Material.
class ChampChoix<T> extends StatelessWidget {
  final String label;
  final T? valeur;
  final List<T> options;
  final String Function(T) libelle;
  final ValueChanged<T?> onChanged;
  final bool obligatoire;
  final String? hint;

  const ChampChoix({
    super.key,
    required this.label,
    required this.valeur,
    required this.options,
    required this.libelle,
    required this.onChanged,
    this.obligatoire = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ChampEtiquete(
      label: label,
      obligatoire: obligatoire,
      child: PremiumSelectField<T>(
        value: valeur,
        hint: hint ?? 'Choisir…',
        sheetTitle: label,
        isRequired: obligatoire,
        options: options.map((o) => SelectOption<T>(value: o, label: libelle(o))).toList(),
        onChanged: onChanged,
      ),
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

/// Rubrique d'un formulaire, au style des cartes de VTC Manager : carte
/// blanche bordée, icône dans une tuile teintée et titre, puis les champs.
class GroupeChamps extends StatelessWidget {
  final String titre;
  final IconData icone;

  /// Teinte de la tuile d'icône ; l'accent de la charte par défaut.
  final Color? couleur;
  final List<Widget> children;

  const GroupeChamps({
    super.key,
    required this.titre,
    required this.icone,
    required this.children,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final accent = couleur ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(titre,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark, letterSpacing: -0.2)),
            ),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
