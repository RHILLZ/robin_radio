import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// A widget for displaying empty state screens with customizable content.
///
/// This widget provides a consistent empty state UI with an icon, title,
/// message, and optional refresh button. It's used when lists or content
/// areas have no data to display.
class EmptyStateWidget extends StatelessWidget {
  /// Creates an empty state widget with customizable content.
  ///
  /// The [title] and [message] parameters are required to provide
  /// meaningful information to the user about the empty state.
  const EmptyStateWidget({
    required this.title,
    required this.message,
    super.key,
    this.onRefresh,
    this.icon = Icons.inbox,
    this.iconColor = Colors.grey,
    this.showRefreshButton = true,
  });

  /// The main title displayed in the empty state.
  final String title;

  /// The descriptive message explaining the empty state.
  final String message;

  /// Optional callback for the refresh button.
  /// When null, the refresh button is hidden regardless of [showRefreshButton].
  final VoidCallback? onRefresh;

  /// The icon to display above the title.
  /// Defaults to [Icons.inbox].
  final IconData icon;

  /// The color of the icon.
  /// Defaults to [Colors.grey].
  final Color iconColor;

  /// Whether to show the refresh button.
  /// The button is only shown if this is true AND [onRefresh] is not null.
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
