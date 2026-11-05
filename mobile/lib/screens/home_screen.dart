import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_header.dart';
import '../core/widgets/header_tabs_pills.dart';
import '../features/immeuble/presentation/pages/immeubles_page.dart';
import '../features/locataire/presentation/pages/locataires_page.dart';
import '../features/loyer/presentation/pages/loyers_page.dart';
import '../features/maintenance/presentation/pages/maintenances_page.dart';
import '../features/parametrage/presentation/pages/settings_screen.dart';
import '../features/tableau_bord/presentation/pages/tableau_bord_page.dart';

/// Index des onglets de la barre de navigation principale.
const _accueilNavIndex = 0;
const _biensNavIndex = 1;
const _locatairesNavIndex = 2;
const _loyersNavIndex = 3;
const _travauxNavIndex = 4;

/// Coquille de l'application, calquée sur VTC Manager : en-tête commun qui
/// porte les sous-onglets en pastilles, barre de navigation flottante.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = _accueilNavIndex;

  /// Sous-onglet du hub Loyers (Échéances / Paiements), posé dans l'en-tête.
  int _ongletLoyers = 0;

  void _naviguer(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final page = switch (_index) {
      _biensNavIndex => const ImmeublesPage(),
      _locatairesNavIndex => const LocatairesPage(),
      _loyersNavIndex => LoyersPage(
          key: ValueKey('loyers-$_ongletLoyers'), onglet: _ongletLoyers),
      _travauxNavIndex => const MaintenancesPage(),
      _ => TableauBordPage(onNaviguer: _naviguer),
    };

    // Les onglets n'ont pas de bouton retour : le retour système y ramène à
    // l'Accueil au lieu de quitter l'application.
    return PopScope(
      canPop: _index == _accueilNavIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _naviguer(_accueilNavIndex);
      },
      child: Scaffold(
        appBar: AppHeader(
          title: switch (_index) {
            _biensNavIndex => 'Biens immobiliers',
            _locatairesNavIndex => 'Locataires',
            _travauxNavIndex => 'Maintenances',
            _ => '',
          },
          showBack: false,
          // Accueil → menu, qui ouvre les réglages (apparence, déconnexion).
          leading: _index == _accueilNavIndex
              ? AppHeaderAction(
                  icon: Icons.menu_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                )
              : null,
          center: switch (_index) {
            _accueilNavIndex => const _Salutation(),
            _loyersNavIndex => HeaderTabsPills(
                labels: const ['Échéances', 'Paiements'],
                index: _ongletLoyers,
                onSelected: (i) => setState(() => _ongletLoyers = i),
              ),
            _ => null,
          },
        ),
        // Seul l'onglet affiché est construit : y revenir recharge ses données,
        // qu'une action menée ailleurs (bail signé, loyer encaissé) a pu changer.
        // Les baux se consultent depuis la fiche du locataire ou du logement.
        body: page,
        extendBody: true,
        bottomNavigationBar: _FloatingNavBar(
          selectedIndex: _index,
          onSelected: _naviguer,
        ),
      ),
    );
  }
}

/// Nom de l'application au centre de l'en-tête de l'accueil.
class _Salutation extends StatelessWidget {
  const _Salutation();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Immobilier Manager',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.dark,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ── Barre de navigation flottante ────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

const _navItems = [
  _NavItem(Icons.home_outlined, Icons.home, 'Accueil'),
  _NavItem(Icons.apartment_outlined, Icons.apartment, 'Biens'),
  _NavItem(Icons.people_outline, Icons.people, 'Locataires'),
  _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet,
      'Loyers'),
  _NavItem(Icons.build_outlined, Icons.build, 'Travaux'),
];

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FloatingNavBar({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Android : barre ancrée pleine largeur, prolongée derrière la barre
    // système. iPhone et web : pilule flottante.
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return isAndroid ? _docked(context) : _floating();
  }

  Widget _docked(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomInset),
      child: _items(),
    );
  }

  Widget _floating() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blanc,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _items(),
        ),
      ),
    );
  }

  Widget _items() {
    return Row(
      children: List.generate(_navItems.length, (i) {
        final item = _navItems[i];
        final selected = i == selectedIndex;
        final couleur = selected ? AppColors.primary : AppColors.grey500;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(i),
            behavior: HitTestBehavior.opaque,
            // Sans fond : l'onglet actif se signale par son icône pleine, sa
            // couleur et la graisse de son libellé.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? item.selectedIcon : item.icon,
                      size: 22, color: couleur),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: couleur,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
