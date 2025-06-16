import 'package:flutter/material.dart';

/// Const widgets for standard app tabs
/// Provides performance benefits and consistency across the app

class RadioTab extends StatelessWidget {
  const RadioTab({super.key});

  @override
  Widget build(BuildContext context) => const Tab(
        icon: Icon(Icons.radio),
        text: 'Radio',
      );
}

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) => const Tab(
        icon: Icon(Icons.album),
        text: 'Albums',
      );
}
