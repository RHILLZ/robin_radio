// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineSongAdapter extends TypeAdapter<OfflineSong> {
  @override
  final int typeId = 0;

  @override
  OfflineSong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineSong(
      id: fields[0] as String,
      songName: fields[1] as String,
      artist: fields[2] as String,
      localPath: fields[4] as String,
      originalUrl: fields[5] as String,
      downloadDate: fields[7] as DateTime,
      albumName: fields[3] as String?,
      duration: fields[6] as int?,
      fileSize: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineSong obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.songName)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.albumName)
      ..writeByte(4)
      ..write(obj.localPath)
      ..writeByte(5)
      ..write(obj.originalUrl)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.downloadDate)
      ..writeByte(8)
      ..write(obj.fileSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineSongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
