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
      duration: json['duration'] == null
          ? null
          : Duration(microseconds: (json['duration'] as num).toInt()),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
      'songName': instance.songName,
      'songUrl': instance.songUrl,
      'artist': instance.artist,
      'albumName': instance.albumName,
      'duration': instance.duration?.inMicroseconds,
      'id': instance.id,
    };
