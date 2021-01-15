import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'const.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ///[INICIANDO FIREBASE]
  await Firebase.initializeApp();
  runApp(MyApp());
}
/////////////////////////////////////
///////////     [INICIO]    /////////////
/////////////////////////////////////
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat FLUTTER',
      theme: ThemeData(
        primaryColor: themeColor,
      ),
      home: LoginScreen(title: 'CHAT FLUTTER'),
      debugShowCheckedModeBanner: false,
    );
  }
}
