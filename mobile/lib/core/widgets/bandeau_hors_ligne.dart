import 'package:flutter/material.dart';

import '../network/diagnostic_reseau.dart';
import '../network/etat_reseau.dart';
import '../theme/app_colors.dart';

/// Bandeau « Wi-Fi et données coupés · activez l'un des deux » (ou « Serveur
/// indisponible · … » selon la cause), posé au-dessus de toute l'application
/// (dans `MaterialApp.builder`) tant que le serveur est hors d'atteinte. Quand
/// des écrans affichent des réponses rejouées depuis le cache, il dit de quand
/// elles datent : « Hors connexion · données de 14:32 ».
///
/// Repris de VTC Manager (paquet `tmk_cache`). L'application reste toujours au
/// même endroit de l'arbre, bandeau visible ou non : la faire changer de
/// parent recréerait le navigateur et perdrait la pile d'écrans. Quand le
/// bandeau est visible, il prend la marge de la barre d'état et l'application
/// ne la réserve plus.
class BandeauHorsLigne extends StatelessWidget {
  final Widget child;
  final EtatReseau? etat;

  const BandeauHorsLigne({super.key, required this.child, this.etat});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CauseIndisponibilite?>(
      valueListenable: etat ?? EtatReseau.instance,
      builder: (context, cause, _) {
        final visible = cause != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cause != null)
              Material(
                color: AppColors.warningTint,
                child: Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                  child: Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Icon(_icone(cause),
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              libelleHorsLigne(cause,
                                  donneesDu: (etat ?? EtatReseau.instance)
                                      .donneesDu,
                                  maintenant: DateTime.now()),
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              key: const ValueKey('application'),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: visible,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  static IconData _icone(CauseIndisponibilite cause) => switch (cause) {
        CauseIndisponibilite.serveur => Icons.dns_rounded,
        CauseIndisponibilite.reseauDesactive => Icons.signal_wifi_off_rounded,
        CauseIndisponibilite.wifiSansInternet =>
          Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
        CauseIndisponibilite.donneesSansInternet =>
          Icons.signal_cellular_connected_no_internet_4_bar_rounded,
        _ => Icons.cloud_off_rounded,
      };
}

/// Constat selon la cause, suivi de l'âge des données rejouées depuis le
/// cache (« · données de 14:32 », « d'hier à 14:32 », « du 24/10 à 14:32 »)
/// ou, à défaut, du geste attendu.
String libelleHorsLigne(
  CauseIndisponibilite cause, {
  DateTime? donneesDu,
  DateTime? maintenant,
}) {
  if (donneesDu == null) return _constatEtGeste(cause);
  String deux(int n) => n.toString().padLeft(2, '0');
  final heure = '${deux(donneesDu.hour)}:${deux(donneesDu.minute)}';
  final ref = maintenant ?? DateTime.now();
  final jour = DateTime(donneesDu.year, donneesDu.month, donneesDu.day);
  final ecart = DateTime(ref.year, ref.month, ref.day).difference(jour).inDays;
  final quand = switch (ecart) {
    0 => 'de $heure',
    1 => "d'hier à $heure",
    _ => 'du ${deux(donneesDu.day)}/${deux(donneesDu.month)} à $heure',
  };
  return '${_constat(cause)} · données $quand';
}

String _constat(CauseIndisponibilite cause) => switch (cause) {
      CauseIndisponibilite.reseauDesactive => 'Wi-Fi et données coupés',
      CauseIndisponibilite.wifiSansInternet => 'Wi-Fi sans internet',
      CauseIndisponibilite.donneesSansInternet =>
        'Données mobiles sans internet',
      CauseIndisponibilite.reseau => 'Hors connexion',
      CauseIndisponibilite.serveur => 'Serveur indisponible',
      CauseIndisponibilite.inconnue => 'Serveur injoignable',
    };

String _constatEtGeste(CauseIndisponibilite cause) => switch (cause) {
      CauseIndisponibilite.reseauDesactive =>
        'Wi-Fi et données coupés · activez l\'un des deux',
      CauseIndisponibilite.wifiSansInternet =>
        'Wi-Fi sans internet · vérifiez la box ou passez sur les données',
      CauseIndisponibilite.donneesSansInternet =>
        'Données mobiles sans internet · réseau faible ou forfait épuisé',
      CauseIndisponibilite.reseau =>
        'Hors connexion · vérifiez le Wi-Fi ou les données',
      CauseIndisponibilite.serveur =>
        'Serveur indisponible · réessayez dans quelques instants',
      CauseIndisponibilite.inconnue => 'Serveur injoignable',
    };
