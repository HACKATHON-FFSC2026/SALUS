import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/admin/domain/models/admin_portal_user.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_dashboard_metrics.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/presentation/providers/admin_portal_providers.dart';
import 'package:salus/features/admin/presentation/widgets/operations_portal_navigation.dart';
import 'package:salus/features/admin/presentation/widgets/operations_portal_collection.dart';
import 'package:salus/features/admin/presentation/widgets/operations_portal_zone_editor.dart';
import 'package:salus/features/admin/presentation/widgets/admin_shelter_form_dialog.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';

part 'operations_portal_sections.dart';
part 'operations_portal_actions.dart';
part 'operations_portal_access.dart';

@RoutePage()
class OperationsPortalPage extends ConsumerStatefulWidget {
  const OperationsPortalPage({super.key});

  @override
  ConsumerState<OperationsPortalPage> createState() =>
      _OperationsPortalPageState();
}

class _OperationsPortalPageState extends ConsumerState<OperationsPortalPage> {
  int _section = 0;
  late final String _uid;
  late final Stream<AdminPortalUser?> _userStream;

  @override
  void initState() {
    super.initState();
    _uid = ref.read(authRepositoryProvider).currentUserId ?? '';
    _userStream = _uid.isEmpty
        ? const Stream<AdminPortalUser?>.empty()
        : ref.read(adminPortalUseCasesProvider).watchUser(_uid);
  }

  void _selectSection(int index) => setState(() => _section = index);

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return _signedOut(context);
    return StreamBuilder<AdminPortalUser?>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null || !user.canAccess) {
          return _noAccess(context);
        }
        final sections = user.isAdmin
            ? const [
                'Vue générale',
                'Organisations',
                'Refuges',
                'Utilisateurs',
                'SOS',
                'Zones',
              ]
            : const ['Vue générale', 'SOS', 'Signalements', 'Zones'];
        final index = _section.clamp(0, sections.length - 1);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 900;
              return Row(
                children: [
                  if (wide)
                    OperationsPortalSideNavigation(
                      sections: sections,
                      selectedIndex: index,
                      user: user,
                      isAdmin: user.isAdmin,
                      onSelect: _selectSection,
                      onSignOut: _signOut,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        OperationsPortalTopBar(
                          user: user,
                          isWide: wide,
                          onSignOut: _signOut,
                        ),
                        Expanded(
                          child: _content(
                            sections[index],
                            user.isAdmin,
                            user.organizationId,
                          ),
                        ),
                        if (!wide)
                          OperationsPortalBottomNavigation(
                            sections: sections,
                            selectedIndex: index,
                            onSelect: _selectSection,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
