// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/song.dart';
import '../modules/player/player_controller.dart';

class TrackListItem extends GetWidget<PlayerController> {
  const TrackListItem({
    required this.song,
    super.key,
    this.index,
    this.onTap,
  });

  final Song song;
  final int? index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final songTitle = _formatSongTitle(song.songName);
    // ignore: unused_local_variable
    final albumName = song.albumName ?? 'Unknown';

    return RepaintBoundary(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(51),
          child: index != null
              ? Text(
                  '${index! + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  _getInitials(songTitle),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          songTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap ??
            () {
              // Handle song selection based on your controller's API
              final songIndex = controller.tracks.indexOf(song);
              if (songIndex >= 0) {
                controller.trackIndex = songIndex;
                controller.playTrack();
              }
            },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.duration != null)
              Text(
                _formatDuration(song.duration!),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatSongTitle(String name) {
    if (name.length < 3) return name;

    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }

  String _getInitials(String title) {
    final words = title.split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0].substring(0, 1).toUpperCase() : '';
    }

    return '${words[0].isNotEmpty ? words[0][0].toUpperCase() : ''}${words.length > 1 && words[1].isNotEmpty ? words[1][0].toUpperCase() : ''}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
