// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class PreviewPage extends StatefulWidget {
  final XFile picture;

  PreviewPage({required this.picture});

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  late XFile picture;
  XFile? outputPicture;

  @override
  void initState() {
    super.initState();
    picture = widget.picture;
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> uploadImageUsingDio(String imagePath) async {
    var url = 'https://b099-43-231-208-200.ngrok.io/otsu_process';
    var dio = Dio();

    var file = File(imagePath);
    var formData = FormData.fromMap({
      "balls": await MultipartFile.fromFile(file.path,
          contentType: MediaType('image', 'png')),
    });

    try {
      var response = await dio.put(url, data: formData);

      if (response.statusCode == 200) {
        print("Upload successful");
        // Handle the response as needed
      } else {
        print("Upload failed");
      }
    } catch (e) {
      print("Exception occurred: $e");
    }
  }

  Future<void> loadImage() async {
    var directory = await syspaths.getExternalStorageDirectory();
    var projectPicturesDirectory =
        Directory('${directory!.path}/Pictures/ProjectPictures');
    var outputFile = File('${projectPicturesDirectory.path}/output.jpg');
    if (await outputFile.exists()) {
      OpenFile.open(outputFile.path);
    } else {
      print("Output file does not exist");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Page'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Image.file(File(picture.path)),
            ElevatedButton(
              onPressed: () async {
                await uploadImageUsingDio(picture.path);
              },
              child: const Text('Upload'),
            ),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);

                if (pickedFile != null) {
                  picture = XFile(pickedFile.path);
                  await uploadImageUsingDio(picture.path);
                } else {
                  print('No image selected.');
                }
              },
              child: const Text('Pick Image'),
            ),
            ElevatedButton(
              onPressed: () async {
                await loadImage();
              },
              child: const Text('Show Output'),
            ),
          ],
        ),
      ),
    );
  }
}
