import 'package:json_annotation/json_annotation.dart';

import 'package:robin_radio/data/models/song.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final String albumName;
  final List<Song> tracks;
  final String? albumCover;
  final String? artist;
  final String? releaseDate;
  final String? id;

  const Album({
    required this.albumName,
    required this.tracks,
    this.albumCover,
    this.artist,
    this.releaseDate,
    this.id,
  });

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumToJson(this);

  // Get total duration of all tracks
  Duration get totalDuration {
    return tracks.fold(Duration.zero,
        (total, song) => total + (song.duration ?? Duration.zero));
  }

  // Get number of tracks
  int get trackCount => tracks.length;

  // Create a copy with some fields changed
  Album copyWith({
    String? albumName,
    List<Song>? tracks,
    String? albumCover,
    String? artist,
    String? releaseDate,
    String? id,
  }) {
    return Album(
      albumName: albumName ?? this.albumName,
      tracks: tracks ?? this.tracks,
      albumCover: albumCover ?? this.albumCover,
      artist: artist ?? this.artist,
      releaseDate: releaseDate ?? this.releaseDate,
      id: id ?? this.id,
    );
  }
}
