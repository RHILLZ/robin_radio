// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({super.key, String? imageUrl, String? albumName})
      : _imageUrl = imageUrl,
        _albumName = albumName;

  final String? _imageUrl, _albumName;

  @override
  Widget build(BuildContext context) {
    final logoImage = Image.asset(
      'assets/logo/rr-logo.png',
      // fit: BoxFit.contain,
      // width: 20.w,
      height: 40.h,
    );
    return Stack(fit: StackFit.loose, children: [
      Container(
        decoration: BoxDecoration(
          border: _imageUrl != null
              ? null
              : Border.all(color: const Color(0XFF6C30C4), width: 5),
          color: Colors.grey.shade300,
        ),
        child: _imageUrl != null ? Image.network(_imageUrl!) : logoImage,
      ),
      _imageUrl == null
          ? Positioned(
              bottom: 40,
              left: 120,
              child: Center(
                child: Text(
                  "Album: $_albumName",
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 20),
                ),
              ),
            )
          : const SizedBox(),
    ]);
  }
}
