import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:salus/features/alerts/presentation/widgets/sos_resolution_modal.dart';

enum _FilterType { all, newAlerts, inProgress, resolved }

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  _FilterType _selectedFilter = _FilterType.all;

  List<SOSAlert> _filterAlerts(List<SOSAlert> alerts) {
    switch (_selectedFilter) {
      case _FilterType.newAlerts:
        return alerts.where((a) => a.respondersCount == 0 && a.status != SOSStatus.resolved).toList();
      case _FilterType.inProgress:
        return alerts.where((a) => a.respondersCount >= 1 && a.status != SOSStatus.resolved).toList();
      case _FilterType.resolved:
        return alerts.where((a) => a.status == SOSStatus.resolved).toList();
      case _FilterType.all:
        return alerts;
    }
  }

  SOSDisplayStatus _getDisplayStatus(SOSAlert alert) {
    if (alert.status == SOSStatus.resolved) {
      return SOSDisplayStatus.resolved;
    } else if (alert.respondersCount >= 1) {
      return SOSDisplayStatus.inProgress;
    } else {
      return SOSDisplayStatus.newAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(nearbyActiveSosStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alertes SOS'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Erreur : $error')),
        data: (alerts) {
          final filteredAlerts = _filterAlerts(alerts);
          
          if (filteredAlerts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _getEmptyMessage(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inactive, fontSize: 16),
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildFilterButtons(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    return _buildAlertCard(alert);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.inactive, width: 0.5)),
      ),
      child: Row(
        children: _FilterType.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _FilterButton(
                label: _getFilterLabel(filter),
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(_FilterType filter) {
    switch (filter) {
      case _FilterType.all:
        return 'Tous';
      case _FilterType.newAlerts:
        return 'Nouveaux';
      case _FilterType.inProgress:
        return 'En cours';
      case _FilterType.resolved:
        return 'Résolus';
    }
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case _FilterType.all:
        return 'Aucune alerte SOS active à proximité.';
      case _FilterType.newAlerts:
        return 'Aucune nouvelle alerte.';
      case _FilterType.inProgress:
        return 'Aucune alerte en cours.';
      case _FilterType.resolved:
        return 'Aucune alerte résolue.';
    }
  }

  Widget _buildAlertCard(SOSAlert alert) {
    final displayStatus = _getDisplayStatus(alert);
    
    return InkWell(
      onTap: () {
        if (displayStatus == SOSDisplayStatus.inProgress) {
          _showResolutionModal(alert);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.distressType.frenchLabel.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(displayStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.displayLocation,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alert.description ?? 'Demande d\'aide urgente',
              style: const TextStyle(color: AppColors.inactive, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: AppColors.secondary, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${alert.respondersCount} intervenant(s)',
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(alert.createdAt),
                  style: const TextStyle(color: AppColors.inactive, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButtons(alert, displayStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SOSDisplayStatus status) {
    Color badgeColor;
    String badgeText;
    
    switch (status) {
      case SOSDisplayStatus.newAlert:
        badgeColor = Colors.red;
        badgeText = 'NOUVEAU';
        break;
      case SOSDisplayStatus.inProgress:
        badgeColor = Colors.orange;
        badgeText = 'EN COURS';
        break;
      case SOSDisplayStatus.resolved:
        badgeColor = Colors.green;
        badgeText = 'RÉSOLU';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(SOSAlert alert, SOSDisplayStatus displayStatus) {
    if (displayStatus == SOSDisplayStatus.resolved) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // Naviguer vers le détail
          },
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('Voir le détail'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    
    // Pour NOUVEAU et EN COURS : uniquement le bouton Annuler le SOS
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            await ref.read(alertsControllerProvider.notifier).cancelSos(alert.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS annulé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Impossible d\'annuler le SOS : $error')),
              );
            }
          }
        },
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Annuler le SOS'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showResolutionModal(SOSAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SosResolutionModal(),
    ).then((result) {
      if (result != null) {
        final resolutionType = result['resolutionType']?.toString();
        final note = result['note'] as String?;
        
        ref.read(alertsControllerProvider.notifier).resolveSos(
          alert.id,
          resolutionType: resolutionType,
          resolutionNote: note,
        ).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Intervention marquée comme résolue'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de la résolution : $error')),
            );
          }
        });
      }
    });
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

enum SOSDisplayStatus { newAlert, inProgress, resolved }

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inactive.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.inactive,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
