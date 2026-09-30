import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/alerts/pages/alerts_page.dart';
import 'package:salus/features/help/pages/help_page.dart';
import 'package:salus/features/home/pages/home_tab_page.dart';
import 'package:salus/features/shelters/pages/shelters_page.dart';
import 'package:toastification/toastification.dart';

/// Un onglet = un icône, un libellé, une page. Ajouter un onglet ne touche
/// que cette liste.
@immutable
class _Tab {
  const _Tab(this.icon, this.label, this.page);

  final IconData icon;
  final String label;
  final Widget page;
}

@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _tabs = <_Tab>[
    _Tab(Icons.home, 'ACCUEIL', HomeTabPage()),
    _Tab(Icons.notifications, 'ALERTES', AlertsPage()),
    _Tab(Icons.map, 'REFUGES', SheltersPage()),
    _Tab(Icons.help, 'AIDE', HelpPage()),
  ];

  /// Nombre d'onglets avant le FAB SOS, qui creuse la BottomAppBar.
  static const _notchAfter = 2;

  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  void _onSosPressed() {
    toastification.show(
      context: context,
      title: const Text('SOS bientôt disponible'),
      type: ToastificationType.warning,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        for (final tab in _tabs) tab.page,
      ]),
      floatingActionButton: GestureDetector(
        onTap: _onSosPressed,
        child: Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.sos,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'SOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: AppColors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _notchAfter; i++)
              _NavItem(
                tab: _tabs[i],
                selected: _index == i,
                onTap: () => _select(i),
              ),
            const SizedBox(width: 72),
            for (var i = _notchAfter; i < _tabs.length; i++)
              _NavItem(
                tab: _tabs[i],
                selected: _index == i,
                onTap: () => _select(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.secondary : AppColors.inactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: color, size: 28),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
