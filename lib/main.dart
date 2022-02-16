import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'dart:convert';
import 'package:zefyr/zefyr.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//String data = '';

//_loadData()async{
//  final first = await Firestore.instance.collection('root').document('-Lc_5WXsrU50kttT9nV9').get();
//  data = first.data['data'];
//}

FlutterLocalNotificationsPlugin notifications;

main() async {
//  print('Loading data');
//  await _loadData();
//  print('Data loaded');

  final androidInitializationSettings =
      AndroidInitializationSettings('ic_launcher');
  final iosInitializationSettings = IOSInitializationSettings();

  final initializationSettings = InitializationSettings(
      androidInitializationSettings, iosInitializationSettings);

  notifications = FlutterLocalNotificationsPlugin();

  notifications.initialize(initializationSettings, onSelectNotification: (str) {
    print(str);
    return;
  });

  final sp = await SharedPreferences.getInstance();
  final email = sp.getString('email');

  runApp(MyApp(email));
}

class MyApp extends StatelessWidget {
  final String email;

  MyApp(this.email);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(email),
      theme: ThemeData(fontFamily: 'OpenSans'),
    );
  }
}

class Less extends StatefulWidget {
  @override
  _LessState createState() => _LessState();
}

class _LessState extends State<Less> {
  ZefyrController _zefyrController;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ZefyrScaffold(
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: ZefyrEditor(
                  controller: _zefyrController, focusNode: focusNode),
            ),
            RaisedButton(onPressed: () {
              final data = json.encode(_zefyrController.document.toJson());
              Firestore.instance.collection('root').document().setData({
                'data': data,
              });
            })
          ],
        ),
      ),
    );
  }
}
