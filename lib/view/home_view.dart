import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:before_after/before_after.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remove_background_ai/Api/Api.dart';
import 'package:share_plus/share_plus.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loaded = false;
  bool removedbg = false;
  bool isloading = false;
  Uint8List? image;
  String imagePath = "";
  var value = 0.5;
  Color selectedColor = Colors.transparent;
  GlobalKey globalKey = GlobalKey();

  // List of colors for background
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.transparent
  ];
  Future<Uint8List> createImageWithBackgroundColor(
      Uint8List imageData, Color color) async {
    ui.Image image = (await decodeImageFromList(imageData));
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0, 0),
            Offset(image.width.toDouble(), image.height.toDouble())));

    // Draw the selected background color
    Paint paint = Paint()..color = color;
    canvas.drawRect(
        Rect.fromPoints(const Offset(0, 0),
            Offset(image.width.toDouble(), image.height.toDouble())),
        paint);

    // Draw the original image on top of the background color
    paint = Paint();
    canvas.drawImage(image, const Offset(0, 0), paint);

    // Create the new image
    ui.Picture picture = recorder.endRecording();
    ui.Image newImage = await picture.toImage(image.width, image.height);
    ByteData? byteData =
        await newImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    return pngBytes;
  }

  //pickImage function
  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // highest quality
        maxWidth: 1200, // increased maximum width
        maxHeight: 900); // increased maximum height);

    if (img != null) {
      imagePath = img.path;

      loaded = true;
      setState(() {});
    } else {
      //
    }
  }

  Future<void> removeBackground() async {
    setState(() {
      isloading = true;
    });
    image = await Api.removebg(imagePath);
    if (image != null) {
      removedbg = true;
      isloading = false;
      setState(() {});
    }
  }

  String getCurrentDate() {
    DateTime now = DateTime.now();
    String formattedDate =
        "${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}";
    return formattedDate;
  }

  String _twoDigits(int n) {
    if (n >= 10) {
      return "$n";
    } else {
      return "0$n";
    }
  }

  Future<void> captureAndSave() async {
    try {
      // Check if the image with removed background is being displayed
      if (value == 0) {
        // Create a new image with the selected background color
        Uint8List newImage =
            await createImageWithBackgroundColor(image!, selectedColor);

        final directory = await getExternalStorageDirectory();
        final File imgFile =
            File('${directory!.path}/removed_bg_image${getCurrentDate()}.png');
        await imgFile.writeAsBytes(newImage);

        print("Image saved: ${imgFile.path}");

        // Share the saved image via social media
        await Share.shareFiles([imgFile.path],
            text: 'Check out this image with removed background!');
      } else {
        // Capture the BeforeAfter widget
        RenderRepaintBoundary boundary = globalKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        ui.Image img = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await img.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final directory = await getExternalStorageDirectory();
        final File imgFile = File(
            '${directory!.path}/before_after_image${getCurrentDate()}.png');
        await imgFile.writeAsBytes(pngBytes);

        print("Image saved: ${imgFile.path}");

        // Share the saved image via social media
        await Share.shareFiles([imgFile.path],
            text: 'Check out this before-after image!');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const Text(
              "✨@Oussema khelifi✨",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white60,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share,
              color: Colors.white,
            ),
            onPressed: () {
              captureAndSave();
            },
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
          child: removedbg
              ? Column(
                  children: [
                    Expanded(
                      child: BeforeAfter(
                        value: value,
                        before: Container(
                          color: selectedColor,
                          child: Image.memory(image!),
                        ),
                        after: Image.file(File(imagePath)),
                        onValueChanged: (value) {
                          setState(() => this.value = value);
                        },
                      ),
                    ),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: colors.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = colors[index];
                                });
                              },
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: colors[index],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedColor == colors[index]
                                        ? Colors.black
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : loaded
                  ? GestureDetector(
                      onTap: pickImage, child: Image.file(File(imagePath)))
                  : Container(
                      padding: const EdgeInsets.all(30),
                      decoration: const BoxDecoration(
                          border: Border.symmetric(
                              vertical: BorderSide(width: 2),
                              horizontal: BorderSide(width: 2)),
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () {
                          pickImage();
                        },
                        child: const Text('Remove background ✨'),
                      ),
                    )),
      bottomNavigationBar: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: loaded ? removeBackground : null,
            child: isloading
                ? const CircularProgressIndicator()
                : const Text('Remove background ✨'),
          )),
    );
  }
}
