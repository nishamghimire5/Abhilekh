// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:digital_humanities/recents_page.dart';

class ImageDisplayPage extends StatelessWidget {
  final File imageFile;

  const ImageDisplayPage({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Display'),
      ),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}
