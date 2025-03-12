import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'song.g.dart';

@JsonSerializable()
class Song extends Equatable {
  final String songName;
  final String songUrl;
  final String artist;
  final String? albumName;

  // Add duration for better player control
  final Duration? duration;

  // Add a unique identifier
  final String? id;

  const Song({
    required this.songName,
    required this.songUrl,
    required this.artist,
    this.albumName,
    this.duration,
    this.id,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);

  // Create a copy with some fields changed
  Song copyWith({
    String? songName,
    String? songUrl,
    String? artist,
    String? albumName,
    Duration? duration,
    String? id,
  }) {
    return Song(
      songName: songName ?? this.songName,
      songUrl: songUrl ?? this.songUrl,
      artist: artist ?? this.artist,
      albumName: albumName ?? this.albumName,
      duration: duration ?? this.duration,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props =>
      [songName, songUrl, artist, albumName, duration, id];
}
