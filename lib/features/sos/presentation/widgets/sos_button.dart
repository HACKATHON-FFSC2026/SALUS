import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salus/core/themes/app_theme.dart';

/// Bouton d'envoi par maintien.
///
/// Le geste est monté sur `onTapDown`/`onTapUp` et pas sur un simple `onTap`:
/// un appui long évite l'envoi accidentel. Ce couple n'est pas atteignable au
/// clavier ni au lecteur d'écran, d'où la `Semantics` exposée en plus.
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.isLoading,
    required this.isEnabled,
    required this.onHold,
  });

  final bool isLoading;

  /// Coupe le maintien quand une alerte est déjà ouverte ou l'utilisateur
  /// n'est pas connecté.
  final bool isEnabled;

  /// Déclenché au relâchement après avoir atteint la durée de maintien.
  final VoidCallback onHold;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  /// 2 s. Assez long pour écarter le appui accidentel, assez court pour ne
  /// pas contraindre une détresse réelle.
  static const _holdDuration = Duration(seconds: 2);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _holdDuration,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.isEnabled) {
        widget.onHold();
      }
      if (mounted) _controller.reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (!widget.isEnabled || widget.isLoading) return;
    _controller.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _stop() {
    if (_controller.status == AnimationStatus.completed) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.isEnabled && !widget.isLoading,
      label: 'Envoyer une alerte SOS',
      hint: 'Maintenez appuyé deux secondes pour envoyer votre position',
      onTap: widget.isEnabled && !widget.isLoading ? widget.onHold : null,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 208,
                      height: 208,
                      child: CircularProgressIndicator(
                        value: _controller.value,
                        strokeWidth: 8,
                        valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isEnabled ? AppColors.sos : AppColors.inactive,
                      ),
                      child: Center(
                        child: widget.isLoading
                            ? const CircularProgressIndicator(color: AppColors.surface)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'MAINTENIR',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'POUR\nENVOYER',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}