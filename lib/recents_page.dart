import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'image_display.dart';

class RecentsPage extends StatefulWidget {
  const RecentsPage({Key? key}) : super(key: key);

  @override
  RecentsPageState createState() => RecentsPageState();
}

class RecentsPageState extends State<RecentsPage> {
  bool _isNavigating = false;

  Future<List<FileSystemEntity>> _getFiles() async {
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final path = Directory('/storage/emulated/0/Project');
      var files = path.listSync();
      files.sort((a, b) => b
          .statSync()
          .modified
          .compareTo(a.statSync().modified)); // Sort by modified date
      return files;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _getFiles(),
        builder: (BuildContext context,
            AsyncSnapshot<List<FileSystemEntity>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading images'));
          } else {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final file = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    if (!_isNavigating) {
                      _isNavigating = true;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ImageDisplayPage(imageFile: File(file.path)),
                        ),
                      );
                      _isNavigating = false;
                    }
                  },
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
