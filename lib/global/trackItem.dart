// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/song.dart';
import '../modules/player/player_controller.dart';

/// A list item widget for displaying track information in a music player.
/// 
/// This widget renders a song as a list tile with optional track number,
/// artist information, duration, and tap handling. It integrates with
/// the PlayerController to handle track selection and playback.
class TrackListItem extends GetWidget<PlayerController> {
  /// Creates a track list item widget.
  /// 
  /// The [song] parameter is required and contains the track information.
  /// The [index] parameter is optional and displays the track number.
  /// The [onTap] parameter is optional and overrides the default tap behavior.
  const TrackListItem({
    required this.song,
    super.key,
    this.index,
    this.onTap,
  });

  /// The song data to display in this list item.
  final Song song;
  
  /// The optional track index to display as a number in the leading avatar.
  /// When null, displays the song title initials instead.
  final int? index;
  
  /// Optional callback for when the list item is tapped.
  /// When null, uses the default behavior of playing the track.
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
    if (name.length < 3) {
      return name;
    }

    final parts = name.substring(3).split('.');
    return parts.isNotEmpty ? parts[0] : name;
  }

  String _getInitials(String title) {
    final words = title.split(' ');
    if (words.isEmpty) {
      return '';
    }
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
