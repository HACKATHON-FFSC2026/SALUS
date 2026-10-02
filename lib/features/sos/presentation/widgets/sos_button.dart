import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salus/core/themes/app_theme.dart';

/// Bouton d'envoi par maintien.
///
/// Le geste est écouté par un `Listener`, pas par un `GestureDetector` :
/// `onTapDown` n'est émis qu'à la confirmation du tap, donc au relâchement,
/// ce qui est l'inverse du comportement voulu ici.
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

  /// Déclenché quand la durée de maintien est atteinte.
  final VoidCallback onHold;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  /// 2 s. Assez long pour écarter le appui accidentel, assez court pour ne
  /// pas contraindre une détresse réelle.
  static const _holdDuration = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _holdDuration,
  )..addListener(_onTick);

  /// Un maintien n'envoie qu'une fois, même si la borne est atteinte puis
  /// redépassée, ou si le pointeur bouge à la fin.
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    if (_controller.value >= 1) _send();
  }

  void _start() {
    if (!widget.isEnabled || widget.isLoading) return;
    _sent = false;
    _controller.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _stop() {
    // La décision se prend sur `value`, jamais sur `AnimationStatus`. À la
    // borne, le statut reste `forward` et la notification `completed` n'arrive
    // qu'au frame suivant — que l'arrêt du ticker empêche. Se fier au statut
    // faisait passer l'envoi pour annulé et le supprimait au relâchement.
    if (_controller.value >= 1) {
      _send();
      return;
    }
    _controller.reverse();
  }

  void _send() {
    if (_sent || !widget.isEnabled) return;
    _sent = true;
    widget.onHold();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.isEnabled && !widget.isLoading,
      label: 'Envoyer une alerte SOS',
      hint: 'Maintenez appuyé deux secondes pour envoyer votre position',
      onTap: widget.isEnabled && !widget.isLoading ? widget.onHold : null,
      child: Listener(
        // `opaque` est nécessaire : le sous-arbre est une chaîne de
        // DecoratedBox et de Stack qui ne rapportent aucun hit au test de
        // touch. En `deferToChild`, le défaut, l'appui n'atteint jamais
        // l'écouteur.
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
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
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.secondary,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isEnabled
                            ? AppColors.sos
                            : AppColors.inactive,
                      ),
                      child: Center(
                        child: widget.isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.surface,
                              )
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
