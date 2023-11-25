// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:image_picker/image_picker.dart';
import 'package:saver_gallery/saver_gallery.dart';

class PreviewPage extends StatefulWidget {
  final XFile picture;

  const PreviewPage({Key? key, required this.picture}) : super(key: key);

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  late XFile picture;
  XFile? outputPicture;
  Future<void>? uploadTask1;
  Future<void>? uploadTask2;
  Future<void>? downloadTask;

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
    String url =
        'http://10.0.2.2:5000/blu_process'; // Update this line with your Flask server URL and endpoint

    var dio = Dio(BaseOptions(
      connectTimeout: 5000,
      receiveTimeout: 3000,
    ));

    var file = File(imagePath);
    if (!await file.exists()) {
      print("File does not exist at path: $imagePath");
      return;
    }

    String fileName = path.basename(file.path);

    var formData = FormData.fromMap({
      "balls": await MultipartFile.fromFile(file.path,
          filename: fileName, contentType: MediaType('image', 'png')),
    });

    try {
      var response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Connection': 'keep-alive',
            'Accept': "image/jpeg",
          },
          responseType: ResponseType.bytes,
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            print("${(sent / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      if (response.statusCode == 200) {
        print("Image uploaded successfully");
      } else {
        print("Image upload failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Image upload error: $e");
    }
  }

  Future<void> loadImage() async {
    final imageName = path.basename(picture.path);
    const url = 'http://10.0.2.2:5000/blu_process';
    final dio = Dio();
    final formData = FormData.fromMap({
      'balls': await MultipartFile.fromFile(picture.path, filename: imageName),
    });
    final response = await dio.post(
      url,
      data: formData,
      options: Options(
        headers: {
          'Connection': 'keep-alive',
          'Accept': "image/jpeg",
        },
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          print("${(received / total * 100).toStringAsFixed(0)}%");
        }
      },
    );

    // Print the response data
    print('Response data: ${response.data}');

    if (response.statusCode == 200) {
      // Request storage permission
      final storagePermission =
          await Permission.manageExternalStorage.request();
      if (!storagePermission.isGranted) {
        print("Storage permission not granted");
        Permission.manageExternalStorage.request();
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$imageName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.data);

      const dirName = 'Project';
      try {
        await SaverGallery.saveFile(
          file: tempFile.path,
          androidExistNotSave: false,
          name: imageName,
          androidRelativePath: dirName,
        );
        print("Image saved successfully");
      } catch (e) {
        print("Error saving image: $e");
      } finally {
        await tempFile.delete();
      }
    } else {
      print("Failed to load image: ${response.statusCode}");
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      uploadTask1 = uploadImageUsingDio(picture.path);
                    });
                  },
                  child: const Text('Upload'),
                ),
                FutureBuilder<void>(
                  future: uploadTask1,
                  builder:
                      (BuildContext context, AsyncSnapshot<void> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.connectionState ==
                        ConnectionState.done) {
                      return const Icon(Icons.check);
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Container();
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        picture = XFile(pickedFile.path);
                        uploadTask2 = uploadImageUsingDio(picture.path);
                      });
                    }
                  },
                  child: const Text('Pick Image'),
                ),
                FutureBuilder<void>(
                  future: uploadTask2,
                  builder:
                      (BuildContext context, AsyncSnapshot<void> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.connectionState ==
                        ConnectionState.done) {
                      return const Icon(Icons.check);
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Container();
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      downloadTask = loadImage();
                    });
                  },
                  child: const Text('Save Output'),
                ),
                FutureBuilder<void>(
                  future: downloadTask,
                  builder:
                      (BuildContext context, AsyncSnapshot<void> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.connectionState ==
                        ConnectionState.done) {
                      return const Icon(Icons.check);
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
