import 'package:flutter/material.dart';

/// A consistent app title widget displaying 'Robin Radio'.
///
/// This widget provides a standardized title with consistent styling
/// for use in app bars and other UI components throughout the app.
class AppTitle extends StatelessWidget {
  /// Creates an app title widget with consistent styling.
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) => const Text(
        'Robin Radio',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      );
}
