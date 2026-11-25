import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immobilier_manager/core/widgets/libelle_bouton.dart';

void main() {
  testWidgets('un libellé trop long tient sur une ligne, tronqué par « … »',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 70,
          child: FilledButton(
            onPressed: () {},
            child: const LibelleBouton('Annuler la réservation'),
          ),
        ),
      ),
    ));

    // Aucun débordement signalé, une seule ligne.
    expect(tester.takeException(), isNull);
    final texte = tester.widget<Text>(find.text('Annuler la réservation'));
    expect(texte.maxLines, 1);
    expect(texte.overflow, TextOverflow.ellipsis);
    final rendu = tester.renderObject<RenderParagraph>(
        find.text('Annuler la réservation'));
    expect(rendu.didExceedMaxLines, isTrue);
  });
}
