import 'package:flutter/material.dart';

/// Const widget for the Robin Radio app title
/// Used in app bars to maintain consistency and performance
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) => const Text(
        'Robin Radio',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      );
}
