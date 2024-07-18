// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' show get;
import 'package:image/image.dart' as img;

import 'package:image_picker/image_picker.dart';
import 'package:saver_gallery/saver_gallery.dart';

class PreviewPage extends StatefulWidget {
  final XFile picture;

  const PreviewPage({Key? key, required this.picture}) : super(key: key);

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  String dropdownValue = 'sauvola';
  late XFile picture;
  XFile? outputPicture;
  Future<void>? uploadTask1;
  Future<void>? uploadTask2;
  Future<String>? downloadTask;

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

  Future<String> uploadImageUsingDio(String endpoint, String imagePath) async {
    String url = 'http://10.0.2.2:5000/$endpoint';

    var dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 3000),
    ));

    var file = File(imagePath);
    if (!await file.exists()) {
      print("File does not exist at path: $imagePath");
      return '';
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
          responseType: ResponseType.plain,
        ),
        onSendProgress: (sent, total) {
          if (total != -1) {
            print("${(sent / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      if (response.statusCode == 200) {
        print("Image uploaded successfully");
        return response.data as String;
      } else {
        print("Image upload failed with status: ${response.statusCode}");
        return '';
      }
    } catch (e) {
      print("Image upload error: $e");
      return '';
    }
  }

  Future<String> loadImage(String endpoint) async {
    final imageName = path.basename(picture.path);
    var url = 'http://10.0.2.2:5000/$endpoint';
    final dio = Dio();
    final formData = FormData.fromMap({
      'balls': await MultipartFile.fromFile(picture.path, filename: imageName),
    });

    try {
      var response = await dio.post(
        url,
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Connection': 'keep-alive',
          },
        ),
      );

      if (response.statusCode == 200) {
        final url = response.data;
        
        var documentDirectory = await getDownloadsDirectory();
        var firstPath = documentDirectory?.path;
        var filePathAndName = documentDirectory!.path + 'pic.jpg';
        //comment out the next three lines to prevent the image from being saved
        //to the device to show that it's coming from the internet
        await Directory(firstPath!).create(recursive: true); // <-- 1
        File file2 = new File(filePathAndName);             // <-- 2
        file2.writeAsBytesSync(url);         // <-- 3
        return filePathAndName;

      } else {
        print("Failed to load image: ${response.statusCode}");
        return '';
      }
    } catch (e) {
      print("Error loading image: $e");
      return '';
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
                DropdownButton<String>(
                  value: dropdownValue,
                  icon: const Icon(Icons.arrow_downward),
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValue = newValue ?? dropdownValue;
                    });
                  },
                  items: <String>[
                    'sauvola',
                    'otsu',
                    'feat',
                    'niblack_m',
                    'niblack_o'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      switch (dropdownValue) {
                        case 'sauvola':
                          uploadTask1 =
                              uploadImageUsingDio('sauvola_process', picture.path);
                          break;
                        case 'otsu':
                          uploadTask1 =
                              uploadImageUsingDio('otsu_process', picture.path);
                          break;
                        case 'feat':
                          uploadTask1 =
                              uploadImageUsingDio('FEAT_process', picture.path);
                          break;
                        case 'niblack_m':
                          uploadTask1 =
                              uploadImageUsingDio('niblack_m', picture.path);
                          break;
                        case 'niblack_o':
                          uploadTask1 =
                              uploadImageUsingDio('niblack_o', picture.path);
                          break;
                        default:
                          break;
                      }
                    });
                  },
                  child: const Text('Upload'),
                ),
                FutureBuilder<void>(
                  future: uploadTask1,
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
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
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        picture = XFile(pickedFile.path);
                        switch (dropdownValue) {
                          case 'sauvola':
                            uploadTask2 =
                                uploadImageUsingDio('sauvola_process', picture.path);
                            break;
                          case 'otsu':
                            uploadTask2 =
                                uploadImageUsingDio('otsu_process', picture.path);
                            break;
                          case 'feat':
                            uploadTask2 =
                                uploadImageUsingDio('FEAT_process', picture.path);
                            break;
                          case 'niblack_m':
                            uploadTask2 =
                                uploadImageUsingDio('niblack_m', picture.path);
                            break;
                          case 'niblack_o':
                            uploadTask2 =
                                uploadImageUsingDio('niblack_o', picture.path);
                            break;
                          default:
                            break;
                        }
                      });
                    }
                  },
                  child: const Text('Pick Image'),
                ),
                FutureBuilder<void>(
                  future: uploadTask2,
                  builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      switch (dropdownValue) {
                        case 'sauvola':
                          downloadTask = loadImage('sauvola_process');
                          break;
                        case 'otsu':
                          downloadTask = loadImage('otsu_process');
                          break;
                        case 'feat':
                          downloadTask = loadImage('FEAT_process');
                          break;
                        case 'niblack_m':
                          downloadTask = loadImage('niblack_m');
                          break;
                        case 'niblack_o':
                          downloadTask = loadImage('niblack_o');
                          break;
                        default:
                          break;
                      }
                    });
                  },
                  child: const Text('Save Output'),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FutureBuilder<String>(
                    future: downloadTask,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
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
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
