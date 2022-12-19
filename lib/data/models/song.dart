import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

@JsonSerializable()
class Song {
  final String songName, songUrl, artist;
  final String? albumName;

  Song(
      {required this.songName,
      required this.songUrl,
      required this.artist,
      this.albumName});

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
  Map<String, dynamic> toJson() => _$SongToJson(this);
}
