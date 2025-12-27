import 'package:flutter/material.dart';

/// A reusable widget for displaying error states with retry functionality.
///
/// This widget provides a consistent error UI across the application,
/// including an icon, title, message, and retry button.
class ErrorStateWidget extends StatelessWidget {
  /// Creates an error state widget.
  ///
  /// The [title], [message], and [onRetry] parameters are required.
  /// The [icon] defaults to [Icons.error_outline] and [iconColor] defaults to [Colors.red].
  const ErrorStateWidget({
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  /// The title text to display for the error.
  final String title;

  /// The detailed error message to display.
  final String message;

  /// Callback function to execute when the retry button is pressed.
  final VoidCallback onRetry;

  /// The icon to display. Defaults to [Icons.error_outline].
  final IconData icon;

  /// The color of the icon. Defaults to [Colors.red].
  final Color iconColor;

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
              const SizedBox(height: 16),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
