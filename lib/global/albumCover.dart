import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({super.key, String? imageUrl}) : _imageUrl = imageUrl;

  final String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    final logoImage = Image.asset(
      'assets/logo/rr-logo.png',
      scale: 6,
      // fit: BoxFit.contain,
      width: 20.w,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
      ),
      child: Image.network(_imageUrl!),
    );
  }
}
