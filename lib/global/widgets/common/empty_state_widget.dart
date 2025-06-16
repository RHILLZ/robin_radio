import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.title,
    required this.message,
    super.key,
    this.onRefresh,
    this.icon = Icons.inbox,
    this.iconColor = Colors.grey,
    this.showRefreshButton = true,
  });

  final String title;
  final String message;
  final VoidCallback? onRefresh;
  final IconData icon;
  final Color iconColor;
  final bool showRefreshButton;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: iconColor,
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              if (showRefreshButton && onRefresh != null) ...[
                SizedBox(height: 3.h),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ],
          ),
        ),
      );
}
