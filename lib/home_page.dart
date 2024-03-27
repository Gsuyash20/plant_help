import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _selectedImage;
  List? _outputs;
  bool _isLoading = false;
  Interpreter? interpreter;


  Future<void> pickImage(ImageSource source) async {
    final pickedFile =
        await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
    await _predictImage(_selectedImage!);
  }


  @override
  void initState() {
    super.initState();
    loadModel();
  }
  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('final_model.tflite');
  }

  Future<void> _predictImage(File image) async {
    if (interpreter == null) return;

    // Pre-process your image before inference if needed
    var input = _preprocessImage(image);
    // Perform inference
    var output = List.filled(interpreter!.getOutputTensors()[0].shape.reduce((a, b) => a * b), 0).reshape(interpreter!.getOutputTensors()[0].shape);
    interpreter?.run(input,output);
print(output);
    setState(() {
      _outputs = output;
      _isLoading = false;
    });
  }

  List<int> _preprocessImage(File imageFile, {int targetWidth = 128, int targetHeight = 128}) {
    // Load the image
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;

    // Resize the image
    image = img.copyResize(image, width: targetWidth, height: targetHeight);

    // Convert the image to a byte list
    Uint8List imageBytes = Uint8List.fromList(img.encodePng(image));

    return imageBytes;
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(250),
        child: Container(
          margin: const EdgeInsets.only(top: 5),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: _boxDecoration(),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 65),
                ElevatedButton(
                  onPressed: () {
                    pickImage(ImageSource.gallery);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OPEN GALLERY',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.image_outlined,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    pickImage(ImageSource.camera);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OPEN CAMERA',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.camera_alt_outlined,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: _selectedImage != null
          ? Image.file(_selectedImage!)
          : const Center(
        child: Text('No image selected'),
      ),
    );
  }
}

BoxDecoration _boxDecoration() {
  return BoxDecoration(
    borderRadius: const BorderRadius.vertical(
      bottom: Radius.circular(20),
    ),
    gradient: LinearGradient(
      colors: [Colors.tealAccent, Colors.green.shade300],
      end: Alignment.topCenter,
      begin: Alignment.bottomCenter,
    ),
  );
}
