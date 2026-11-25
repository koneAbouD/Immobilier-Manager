import 'package:flutter/widgets.dart';

/// Libellé de bouton : toujours sur une seule ligne. Si la place manque (écran
/// étroit, grande taille de police), il est tronqué par des points de
/// suspension (« Annuler » → « Annul… ») au lieu de passer à la ligne ou de
/// déborder.
class LibelleBouton extends StatelessWidget {
  final String texte;
  final TextStyle? style;
  final TextAlign? textAlign;

  const LibelleBouton(this.texte, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) => Text(
        texte,
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
}
