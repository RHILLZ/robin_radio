// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robin_radio/data/models/song.dart';
import 'package:robin_radio/modules/player/player_controller.dart';

class TrackListItem extends GetWidget<PlayerController> {
  const TrackListItem({super.key, required Song song}) : _song = song;

  final Song _song;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(_song.songName.substring(0, 2)),
      title: Text(
        _song.songName.substring(3).split('.')[0],
        style: const TextStyle(fontSize: 18),
      ),
      subtitle: Text(_song.albumName ?? 'unknown'),
    );
  }
}
