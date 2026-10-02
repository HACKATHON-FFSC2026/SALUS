import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/sos_provider.dart';
import '../widgets/sos_button.dart';
import '../widgets/call_emergency_button.dart';
import '../widgets/sos_distress_modal.dart';

@RoutePage()
class SosPage extends ConsumerStatefulWidget {
  const SosPage({super.key});

  @override
  ConsumerState<SosPage> createState() => _SosPageState();
}

class _SosPageState extends ConsumerState<SosPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _showDistressModal();
      }
    });
  }

  void _showDistressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SosDistressModal(),
    ).then((result) {
      _animationController.reset();
      if (result != null) {
        final distressType = result['distressType'] as DistressType;
        final description = result['description'] as String?;
        ref.read(sosControllerProvider.notifier).triggerSos(
          distressType: distressType,
          description: description,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _makeEmergencyCall() async {
    final Uri url = Uri.parse('tel:117');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosControllerProvider);

    ref.listen<SosState>(sosControllerProvider, (previous, next) {
      if (next.status == SosStatus.error) {
        _animationController.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Erreur lors de l\'envoi'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next.status == SosStatus.success) {
        _animationController.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerte SOS enregistrée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              "Besoin d'aide?",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'SOS',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Votre position sera transmise aux services de secours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.inactive,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
            const Spacer(),

            // Bouton SOS principal avec animation
            SosButton(
              controller: _animationController,
              isLoading: sosState.status == SosStatus.loading,
              onTapDown: () {
                if (sosState.status != SosStatus.loading) {
                  _animationController.forward();
                }
              },
              onTapUp: () {
                if (_animationController.status != AnimationStatus.completed) {
                  _animationController.reverse();
                }
              },
            ),

            const Spacer(),

            // Bouton Appeler les secours
            CallEmergencyButton(
              onPressed: _makeEmergencyCall,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _animationController.reset();
                ref.read(sosControllerProvider.notifier).reset();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: AppColors.inactive,
                  fontSize: 15,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}