import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/widgets/app_logo.dart';
import 'package:salus/features/admin/domain/models/admin_portal_user.dart';

class OperationsPortalSideNavigation extends StatelessWidget {
  const OperationsPortalSideNavigation({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.user,
    required this.isAdmin,
    required this.onSelect,
    required this.onSignOut,
  });

  final List<String> sections;
  final int selectedIndex;
  final AdminPortalUser user;
  final bool isAdmin;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.apartment,
    Icons.home_work_outlined,
    Icons.people_outline,
    Icons.sos,
    Icons.report_gmailerrorred_outlined,
    Icons.map_outlined,
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 248,
    color: AppColors.primary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 16, 30),
          child: Row(children: [AppLogo(size: 104)]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            isAdmin ? 'ADMINISTRATION' : 'OPÉRATIONS',
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < sections.length; i++)
          ListTile(
            selected: selectedIndex == i,
            selectedTileColor: AppColors.primary.withValues(alpha: .78),
            leading: Icon(
              _icons[i == 0
                  ? 0
                  : isAdmin
                  ? i
                  : i + 3],
              color: selectedIndex == i ? AppColors.secondary : Colors.white70,
            ),
            title: Text(
              sections[i],
              style: TextStyle(
                color: selectedIndex == i ? Colors.white : Colors.white70,
                fontWeight: selectedIndex == i
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
            onTap: () => onSelect(i),
          ),
        const Spacer(),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(
            user.displayName ?? 'Équipe',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            user.email ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white70),
          title: const Text(
            'Déconnexion',
            style: TextStyle(color: Colors.white70),
          ),
          onTap: onSignOut,
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

class OperationsPortalTopBar extends StatelessWidget {
  const OperationsPortalTopBar({
    super.key,
    required this.user,
    required this.isWide,
    required this.onSignOut,
  });

  final AdminPortalUser user;
  final bool isWide;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Container(
    height: 78,
    padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 18),
    color: Colors.white,
    child: Row(
      children: [
        if (!isWide) const AppLogo(size: 48),
        if (!isWide) const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Centre de coordination',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const Icon(Icons.circle, color: AppColors.secondary, size: 10),
        const SizedBox(width: 7),
        Text(
          isWide ? 'Connecté · ${user.displayName ?? 'Équipe'}' : 'En ligne',
          style: const TextStyle(color: AppColors.inactive, fontSize: 12),
        ),
        if (!isWide)
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
  );
}

class OperationsPortalBottomNavigation extends StatelessWidget {
  const OperationsPortalBottomNavigation({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.apartment,
    Icons.home_work_outlined,
    Icons.people_outline,
    Icons.sos,
    Icons.report_gmailerrorred_outlined,
    Icons.map_outlined,
  ];

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onSelect,
    destinations: [
      for (var i = 0; i < sections.length; i++)
        NavigationDestination(
          icon: Icon(
            _icons[i == 0
                ? 0
                : sections.length == 5 && sections[1] == 'Organisations'
                ? i
                : i + 3],
          ),
          label: sections[i],
        ),
    ],
  );
}
