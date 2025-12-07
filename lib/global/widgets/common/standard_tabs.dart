import 'package:flutter/material.dart';

/// Const widgets for standard app tabs
/// Provides performance benefits and consistency across the app

/// A standard tab widget for the Radio section.
class RadioTab extends StatelessWidget {
  /// Creates a RadioTab widget.
  const RadioTab({super.key});

  @override
  Widget build(BuildContext context) => const Tab(
        icon: Icon(Icons.radio),
        text: 'Radio',
      );
}

/// A standard tab widget for the Albums section.
class AlbumsTab extends StatelessWidget {
  /// Creates an AlbumsTab widget.
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) => const Tab(
        icon: Icon(Icons.album),
        text: 'Albums',
      );
}
