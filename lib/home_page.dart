// ignore_for_file: avoid_print

import 'package:camera/camera.dart';
import 'package:digital_humanities/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:circular_bottom_navigation/circular_bottom_navigation.dart';
import 'package:circular_bottom_navigation/tab_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPos = 0;

  double bottomNavBarHeight = 60;

  List<TabItem> tabItems = List.of([
    TabItem(
      Icons.home,

      "Home",
      const Color(0xFFB67E6F),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
          color: Color(0xFFFFFFFF)
      ),
    ),
    TabItem(
      Icons.camera,
      "Capture",
      const Color(0xFFB67E6F),
      labelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          color: Color(0xFFFFFFFF)
      ),
    ),
  ]);

  late CircularBottomNavigationController _navigationController;

  @override
  void initState() {
    super.initState();
    _navigationController = CircularBottomNavigationController(selectedPos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: bottomNavBarHeight),
            child: bodyContainer(),
          ),
          Align(alignment: Alignment.bottomCenter, child: bottomNav())
        ],
      ),
    );
  }

  Widget bodyContainer() {
    List<String> files = [];
    if (selectedPos == 1) {
      return FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (BuildContext context,
            AsyncSnapshot<List<CameraDescription>> snapshot) {
          if (snapshot.hasData) {
            return CameraPage(cameras: snapshot.data!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            const Color(0xffe9dcc0),
            Colors.brown[200]!,
            const Color(0xffe9dcc0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Center(
              child: Column(
                children: [
                  Image.asset('assets/logo.png',
                    width: 100,
                    height: 100,),
                  const Text(
                    'Welcome to Abhilekh\nOpen the Camera to Begin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '"Abhilekh" is a pioneering project aimed at digitizing historical Newari stone inscriptions. It uses advanced image processing techniques, including a novel approach combining fuzzy entropy-based adaptive thresholding and Fast Fourier Transform, to convert these inscriptions into a machine-readable format. This initiative promises to enhance the preservation, study, and sharing of our cultural heritage.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  width: 130,
                  height: 50,
                  margin:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      files[index],
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomNav() {
    return CircularBottomNavigation(
      tabItems,
      controller: _navigationController,
      selectedPos: selectedPos,
      barHeight: bottomNavBarHeight,
      barBackgroundColor: Colors.brown,
      backgroundBoxShadow: const <BoxShadow>[
        BoxShadow(color: Colors.black45, blurRadius: 10.0),
      ],
      animationDuration: const Duration(milliseconds: 300),
      selectedCallback: (int? selectedPos) {
        setState(() {
          this.selectedPos = selectedPos ?? 0;
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _navigationController.dispose();
  }
}
