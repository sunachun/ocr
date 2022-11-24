import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
// main関数内での非同期処理（下のFirebase.initializeApp）を可能にする処理
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

// アプリ画面を描画する前に、Firebaseの初期化処理を実行
class _AppState extends State<App> {
  Future<FirebaseApp> _initialize() async {
    return Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialize(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
// MaterialAppの前なので、 textDirection: TextDirection.ltr
// がないと、文字の方向がわからないというエラーになる
          return Center(
              child: Text(
            '読み込みエラー',
            textDirection: TextDirection.ltr,
          ));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
// 上記と同様。 textDirection: TextDirection.ltr が必要
        return Center(
            child: Text(
          '読み込み中...',
          textDirection: TextDirection.ltr,
        ));
      },
    );
  }
}

// OCRアプリ画面の描画
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日本語OCR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '日本語OCR'),
    );
  }
}

class MyHomePage extends StatefulWidget {
// null safety対応のため、Keyに?をつけ、titleは初期値""を設定
  MyHomePage({Key? key, this.title = ""}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
// null safety対応のため、?でnull許容
  File? _image;
  final _picker = ImagePicker();
// null safety対応のため、?でnull許容
  String? _result;
  @override
  void initState() {
    super.initState();
    _signIn();
  }

// 匿名でのFirebaseログイン処理
  void _signIn() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future _getImage(FileMode fileMode) async {
// null safety対応のため、lateで宣言
    late final _pickedFile;
// image_pickerの機能で、カメラからとギャラリーからの2通りの画像取得（パスの取得）を設定
    if (fileMode == FileMode.CAMERA) {
      _pickedFile = await _picker.getImage(source: ImageSource.camera);
    } else {
      _pickedFile = await _picker.getImage(source: ImageSource.gallery);
    }
    setState(() {
      if (_pickedFile != null) {
        _image = File(_pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('日本語OCR'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
// 写真のサイズによって画面はみ出しエラーが生じるのを防ぐため、
// Columnの上にもSingleChildScrollViewをつける
          child: SingleChildScrollView(
            child: Column(children: [
// 画像を取得できたら表示
// null safety対応のため_image!とする（_imageはnullにならない）
              if (_image != null) Image.file(_image!, height: 400),
// 画像を取得できたら解析ボタンを表示
              if (_image != null) _analysisButton(),
              Container(
                  height: 240,
// OCR（テキスト検索）の結果をスクロール表示できるようにするため
// 結果表示部分をSingleChildScrollViewでラップ
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Text((() {
// OCR（テキスト認識）の結果（_result）を取得したら表示
                        if (_result != null) {
// null safety対応のため_result!とする（_resultはnullにならない）
                          return _result!;
                        } else if (_image != null) {
                          return 'ボタンを押すと解析が始まります';
                        } else {
                          return 'OCR（テキスト認識）したい画像を撮影または読込んでください';
                        }
                      }())))),
            ]),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
// カメラ起動ボタン
          FloatingActionButton(
            onPressed: () => _getImage(FileMode.CAMERA),
            tooltip: 'Pick Image from camera',
            child: Icon(Icons.camera_alt),
          ),
// ギャラリー（ファイル）検索起動ボタン
          FloatingActionButton(
            onPressed: () => _getImage(FileMode.GALLERY),
            tooltip: 'Pick Image from gallery',
            child: Icon(Icons.folder_open),
          ),
        ],
      ),
    );
  }

// OCR（テキスト認識）開始処理
  Widget _analysisButton() {
    return ElevatedButton(
      child: Text('解析'),
      onPressed: () async {
// null safety対応のため_image!とする（_imageはnullにならない）
        List<int> _imageBytes = _image!.readAsBytesSync();
        String _base64Image = base64Encode(_imageBytes);
// Firebase上にデプロイしたFunctionを呼び出す処理
        HttpsCallable _callable =
            FirebaseFunctions.instance.httpsCallable('annotateImage');
        final params = '''{
"image": {"content": "$_base64Image"},
"features": [{"type": "TEXT_DETECTION"}],
"imageContext": {
"languageHints": ["ja"]
}
}''';
        final _text = await _callable(params).then((v) {
          return v.data[0]["fullTextAnnotation"]["text"];
        }).catchError((e) {
          print('ERROR: $e');
          return '読み取りエラーです';
        });
// OCR（テキスト認識）の結果を更新
        setState(() {
          _result = _text;
        });
      },
    );
  }
}

// カメラ経由かギャラリー（ファイル）経由かを示すフラグ
enum FileMode {
  CAMERA,
  GALLERY,
}
