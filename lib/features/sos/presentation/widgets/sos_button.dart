import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';

class SosButton extends StatelessWidget {
  final AnimationController controller;
  final bool isLoading;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const SosButton({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => onTapUp(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Container(
            width: 260,
            height: 260,
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
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: controller.value,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Container(
                    width: 210,
                    height: 210,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sos,
                    ),
                    child: Center(
                      child: isLoading
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
    );
  }
}