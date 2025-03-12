// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
      albumName: json['albumName'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
      albumCover: json['albumCover'] as String?,
      artist: json['artist'] as String?,
      releaseDate: json['releaseDate'] as String?,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
      'albumName': instance.albumName,
      'tracks': instance.tracks,
      'albumCover': instance.albumCover,
      'artist': instance.artist,
      'releaseDate': instance.releaseDate,
      'id': instance.id,
    };
