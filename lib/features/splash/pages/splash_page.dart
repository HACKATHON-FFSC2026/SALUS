import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salus/core/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/widgets/app_logo.dart';
import 'package:salus/core/utils/guest_session.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final guest = await isGuestMode();
      if (!mounted) return;
      context.router.replace(guest ? const MainRoute() : const LoginRoute());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: AppLogo(size: 200)),
    );
  }
}
