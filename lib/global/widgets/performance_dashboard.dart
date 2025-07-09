import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/performance_service.dart';

/// Performance dashboard widget for monitoring app performance in debug mode
class PerformanceDashboard extends StatefulWidget {
  const PerformanceDashboard({super.key});

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> {
  final PerformanceService _performanceService = PerformanceService();
  bool _isPerformanceEnabled = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _checkPerformanceStatus();
  }

  Future<void> _checkPerformanceStatus() async {
    if (!kDebugMode) return;

    final isEnabled =
        await _performanceService.isPerformanceCollectionEnabled();
    if (mounted) {
      setState(() {
        _isPerformanceEnabled = isEnabled;
      });
    }
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  Future<void> _trackMemoryUsage() async {
    await _performanceService.trackMemoryUsage();
    Get.snackbar(
      'Performance',
      'Memory usage tracked',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  Future<void> _trackCustomEvent() async {
    await _performanceService.trackCustomEvent(
      'manual_performance_check',
      attributes: {
        'triggered_by': 'user',
        'screen': 'performance_dashboard',
        'timestamp': DateTime.now().toIso8601String(),
      },
      metrics: {
        'check_count': 1,
      },
    );
    Get.snackbar(
      'Performance',
      'Custom event tracked',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Toggle button
          FloatingActionButton.small(
            onPressed: _toggleVisibility,
            backgroundColor: Colors.orange.withValues(alpha: 0.8),
            child: Icon(
              _isVisible ? Icons.close : Icons.analytics,
              color: Colors.white,
            ),
          ),

          // Dashboard panel
          if (_isVisible) ...[
            const SizedBox(height: 8),
            Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Performance Monitor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status
                  _buildStatusRow(
                    'Performance Collection',
                    _isPerformanceEnabled ? 'Enabled' : 'Disabled',
                    _isPerformanceEnabled ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),

                  _buildStatusRow(
                    'Build Mode',
                    kDebugMode ? 'Debug' : 'Release',
                    kDebugMode ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  const Text(
                    'Manual Tracking:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _trackMemoryUsage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.withValues(alpha: 0.7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Memory',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _trackCustomEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withValues(alpha: 0.7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Event',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Performance data appears in Firebase Console within 12 hours.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
}
