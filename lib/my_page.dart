import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key, required this.message}) : super(key: key);
  final String message;

  @override
  State<StatefulWidget> createState() => new MyPageState();
}

class MyPageState extends State<MyPage> {
  XFile? _image;
  File? fileImage;
  File? pickImage;
  late InputImage _inputImage;
  final _stateController = TextEditingController();
  final _visionTextController = TextEditingController();
  //final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.chinese);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    this._stateController.dispose();
    super.dispose();
  }

  Future getImage() async {
    var image = await ImagePicker().pickImage(source: ImageSource.camera);
    final path = image!.path;
    setState(() {
      this._image = image!;
      pickImage = File(path);
    });
    _inputImage = InputImage.fromFilePath(path);
  }

  Future getImageGallery() async {
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);
    final path = image!.path;
    setState(() {
      this._image = image!;
      pickImage = File(path);
    });
    _inputImage = InputImage.fromFilePath(path);
  }

  void vision() async {
    if (this._image != null) {
      // MLKitCompatibleImage visionImage =
      //     FirebaseVisionImage.fromFile(this._image);

      dynamic visionText = await _textRecognizer.processImage(_inputImage);

      String text = visionText.text;
      print(text);

      var buf = new StringBuffer();
      for (TextBlock block in visionText.blocks) {
        final Rect boundingBox = block.boundingBox;
        final List<Offset> cornerPoints = block.cornerPoints.cast<Offset>();
        final String text = block.text;
        final List<dynamic> languages = block.recognizedLanguages;
        print(languages);
        buf.write("=====================\n");
        for (TextLine line in block.lines) {
          // Same getters as TextBlock
          buf.write("${line.text}\n");
          for (TextElement element in line.elements) {
            // Same getters as TextBlock
          }
        }
      }
      setState(() {
        this._visionTextController.text = buf.toString();
      });
    } else {
      print('画像がありません');
    }
  }

  void showTime() {
    setState(() {});
  }

  // void loadOnPressed() {
  //   FirebaseFirestore.instance
  //       .doc("sample/sandwichData")
  //       .get()
  //       .then((DocumentSnapshot ds) {
  //     setState(() {
  //       this._stateController.text = ds["hotDogStatus"];
  //     });
  //     print("status=$this.status");
  //   });
  // }
  //
  // void saveOnPressed() {
  //   FirebaseFirestore.instance
  //       .doc("sample/sandwichData")
  //       .update({"hotDogStatus": _stateController.text})
  //       .then((value) => print("success"))
  //       .catchError((value) => print("error $value"));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR APP'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: TextField(
                            controller: _stateController,
                          ),
                        ),
                        // Padding(
                        //   padding: EdgeInsets.all(2.0),
                        //   child: ElevatedButton(
                        //       onPressed: saveOnPressed, child: Text("Save")),
                        // ),
                        // Padding(
                        //     padding: EdgeInsets.all(2.0),
                        //     child: ElevatedButton(
                        //         onPressed: loadOnPressed, child: Text("Load")))
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(2.0),
                              child: ElevatedButton(
                                onPressed: getImageGallery,
                                child: Text("フォルダから選択"),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(2.0),
                              child: ElevatedButton(
                                onPressed: getImage,
                                child: Text("写真を撮る"),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(2.0),
                              child: ElevatedButton(
                                onPressed: vision,
                                child: Text("Vision Api"),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _visionTextController,
                          minLines: 6,
                          maxLines: 30,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Container(
                          //width: MediaQuery.of(context).size.width,
                          //height: 300,
                          child: FittedBox(
                            fit: BoxFit.fitHeight,
                            child: _image == null
                                ? Text('No image selected.')
                                : Image.file(pickImage!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
