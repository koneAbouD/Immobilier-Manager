class TableauBord {
  final DateTime periode;
  final int nombreImmeubles;
  final int nombreAppartements;
  final int nombreAppartementsOccupes;
  final int tauxOccupation;
  final int nombreLocatairesActifs;
  final double loyersAttendus;
  final double loyersEncaisses;
  final int tauxRecouvrement;
  final double impayes;
  final int nombreEcheancesEnRetard;
  final int maintenancesOuvertes;
  final int maintenancesUrgentes;

  const TableauBord({
    required this.periode,
    required this.nombreImmeubles,
    required this.nombreAppartements,
    required this.nombreAppartementsOccupes,
    required this.tauxOccupation,
    required this.nombreLocatairesActifs,
    required this.loyersAttendus,
    required this.loyersEncaisses,
    required this.tauxRecouvrement,
    required this.impayes,
    required this.nombreEcheancesEnRetard,
    required this.maintenancesOuvertes,
    required this.maintenancesUrgentes,
  });

  double get resteAEncaisser => (loyersAttendus - loyersEncaisses).clamp(0, double.infinity);
}
