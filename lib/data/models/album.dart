import 'package:json_annotation/json_annotation.dart';

import 'package:robin_radio/data/models/song.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final String albumName;
  final List<Song> tracks;
  final String? albumCover;

  Album({required this.albumName, required this.tracks, this.albumCover});

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumToJson(this);
}
