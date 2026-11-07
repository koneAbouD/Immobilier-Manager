import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Centre par défaut des cartes sans position : Abidjan.
const kCentreParDefaut = LatLng(5.3600, -4.0083);

/// Carte OpenStreetMap avec un repère sur [position]. Avec [onTap], toucher
/// la carte y déplace le repère ; sans, la carte est un simple aperçu.
class CartePosition extends StatefulWidget {
  final LatLng? position;
  final double hauteur;
  final ValueChanged<LatLng>? onTap;

  const CartePosition({super.key, required this.position, this.hauteur = 200, this.onTap});

  @override
  State<CartePosition> createState() => _CartePositionState();
}

class _CartePositionState extends State<CartePosition> {
  final _controller = MapController();

  @override
  void didUpdateWidget(covariant CartePosition old) {
    super.didUpdateWidget(old);
    // Recentre sur une position venue de l'extérieur (bouton « Ma position »).
    final p = widget.position;
    if (p != null && p != old.position) {
      _controller.move(p, _controller.camera.zoom < 15 ? 17 : _controller.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.hauteur,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: p ?? kCentreParDefaut,
            initialZoom: p == null ? 12 : 17,
            onTap: widget.onTap == null ? null : (_, point) => widget.onTap!(point),
            interactionOptions: InteractionOptions(
              flags: widget.onTap == null ? InteractiveFlag.none : InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tmk.immobilier_manager',
            ),
            if (p != null)
              MarkerLayer(markers: [
                Marker(
                  point: p,
                  width: 44,
                  height: 44,
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.location_on_rounded, size: 44, color: AppColors.error),
                ),
              ]),
            const SimpleAttributionWidget(source: Text('OpenStreetMap')),
          ],
        ),
      ),
    );
  }
}

/// Position actuelle du téléphone, après accord de l'utilisateur. Lève un
/// message lisible si la localisation est coupée ou refusée.
Future<LatLng> positionActuelle() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw 'La localisation du téléphone est désactivée. Activez-la, puis réessayez.';
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw 'L\'accès à la position a été refusé. Autorisez-le dans les réglages du téléphone.';
  }
  final p = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
  );
  return LatLng(p.latitude, p.longitude);
}

/// Ouvre l'itinéraire vers [position] dans l'application de cartes du téléphone.
Future<bool> ouvrirItineraire(LatLng position) => launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${position.latitude},${position.longitude}'),
      mode: LaunchMode.externalApplication,
    );

/// « 5.360012, -4.008301 ».
String formatPosition(LatLng p) => '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
