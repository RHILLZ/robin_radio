// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Song _$SongFromJson(Map<String, dynamic> json) => Song(
      songName: json['songName'] as String,
      songUrl: json['songUrl'] as String,
      artist: json['artist'] as String,
      albumName: json['albumName'] as String?,
    );

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
      'songName': instance.songName,
      'songUrl': instance.songUrl,
      'artist': instance.artist,
      'albumName': instance.albumName,
    };
