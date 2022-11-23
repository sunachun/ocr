//パッケージのインポート
import 'dart:io';

import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Text? _text;
  Image? _image;
  //変数の宣言
  File? image;
  final picker = ImagePicker();
  File? _scannedImage;

  Future<void> _ocr() async {
    final pickerFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickerFile == null) {
      return;
    }
    final InputImage imageFile = InputImage.fromFilePath(pickerFile.path);
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.japanese);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(imageFile);
    String text = recognizedText.text;
    /*
    for (TextBlock block in recognizedText.blocks) {
      // ブロック単位で取得したい情報がある場合はここに記載
      for (TextLine line in block.lines) {
        // ライン単位で取得したい情報がある場合はここに記載
      }
    }
    */

    // 画面に反映
    setState(() {
      _text = Text(text);
      _image = Image.file(File(pickerFile.path));
    });

    // リソースの開放
    textRecognizer.close();
  }

  Future<void> camera() async {
    final pickerFile = await picker.getImage(source: ImageSource.camera);
  }

  // ラベリングを行う
  Future<void> _labeling() async {
    final pickerFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickerFile == null) {
      return;
    }
    final InputImage imageFile = InputImage.fromFilePath(pickerFile.path);
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.japanese);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(imageFile);
    String text = recognizedText.text;

    // 画面に反映
    setState(() {
      _text = Text(text);
      _image = Image.file(File(pickerFile.path));
    });

    // リソースの開放
    textRecognizer.close();
  }

  //カメラで撮影した画像を取得する命令
  Future getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
      }
    });
  }

  //端末のアルバムに保存されている画像を取得する命令
  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
      }
    });
  }

  openImageScanner(BuildContext context) async {
    var imageScanner = await DocumentScannerFlutter.launch(
      context,
    );
    if (imageScanner != null) {
      _scannedImage = imageScanner;
      final InputImage imageFile = InputImage.fromFilePath(imageScanner.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.japanese);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(imageFile);
      String text = recognizedText.text;
      setState(() {
        print('完了');
        _text = Text(text);
        _image = Image.file(File(imageScanner.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _text != null
                      ? _text!
                      : Column(
                          children: [
                            //呼び出しボタン
                            ElevatedButton(
                                onPressed: () {
                                  _labeling();
                                },
                                child: const Text('カメラで撮影する')),
                            const SizedBox(height: 5),
                            //呼び出しボタン
                            ElevatedButton(
                                onPressed: () {
                                  _ocr();
                                },
                                child: const Text('アルバムから取得する')),
                            const SizedBox(height: 5),
                            //呼び出しボタン
                            ElevatedButton(
                                onPressed: () {
                                  openImageScanner(context);
                                },
                                child: const Text('scanner')),
                          ],
                        ),
                  if (_image != null) SafeArea(child: _image!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
