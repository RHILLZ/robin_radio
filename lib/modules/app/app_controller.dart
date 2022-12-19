import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:robin_radio/data/models/album.dart';
import 'package:robin_radio/data/models/song.dart';
import 'package:robin_radio/global/trackItem.dart';
import 'package:robin_radio/modules/home/trackListView.dart';
import 'package:robin_radio/modules/player/player_controller.dart';

class AppController extends GetxController {
  final MiniplayerController miniPlayerController = MiniplayerController();
  final storage = FirebaseStorage.instance;
  dynamic storageRef;
  dynamic artist;
  dynamic listFiles;
  final RxList _robinsMusic = [].obs;
  int _currentMax = 15;

  get robinsMusic => _robinsMusic;

  @override
  void onInit() async {
    storageRef = storage.ref();
    setRefs();
    await getMusic();
    super.onInit();
  }

  setRefs() {
    artist = storageRef.child('Artist');
  }

  getMusic() async {
    listFiles = await artist.listAll();
    for (var artist in listFiles.prefixes) {
      final nameOfArtist = artist.name;
      String nameOfAlbum = '';
      String? albumArt;
      final albums = await artist.listAll();
      for (var album in albums.prefixes) {
        List<Song> tracks = [];
        nameOfAlbum = album.name;
        final songs = await album.listAll();
        for (var song in songs.items) {
          final url = await song.getDownloadURL();
          final nameOfSong = await song.name;
          albumArt = nameOfSong.endsWith('.jpg') ? url : null;
          if (!nameOfSong.endsWith('.jpg')) {
            tracks.add(Song(
                songName: nameOfSong,
                songUrl: url,
                artist: nameOfArtist,
                albumName: nameOfAlbum));
          }
        }
        _robinsMusic.add(Album(
            albumName: nameOfAlbum, tracks: tracks, albumCover: albumArt));
      }
    }
  }

  openTrackList(Album album) => Get.bottomSheet(TrackListView(album: album),
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent);
}
