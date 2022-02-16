import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notekeeper/bloc/login_bloc.dart';
import 'package:notekeeper/my_flutter_app_icons.dart';
import 'dart:math' as math;
import 'package:notekeeper/screens/home_screen.dart';
import 'package:notekeeper/utils/utils.dart' as utils;

class LoginScreen extends StatefulWidget {
  final String email;

  LoginScreen(this.email);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final loginBloc = LoginBloc();
  final math.Random _random = math.Random();
  Color _color = Color.fromRGBO(math.Random().nextInt(255),
      math.Random().nextInt(255), math.Random().nextInt(255), 1.0);
  AnimationController _controller;
  Widget _animatedBuilder;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 2000))
          ..forward();
    super.initState();

    final saveTheme = TextStyle(
        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 33.0);
    final yourTheme = TextStyle(
        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 26.0);
    final dataTheme = TextStyle(
        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.0);
    final inTheTheme = TextStyle(
        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0);
    final cloudTheme = TextStyle(
        fontWeight: FontWeight.bold, color: Colors.white, fontSize: 30.0);

    _animatedBuilder = AnimatedBuilder(
        animation: _controller,
        child: Column(
          children: <Widget>[
            Text('Save', style: saveTheme),
            Text('your', style: yourTheme),
            Text('notes', style: dataTheme),
            Text('in the', style: inTheTheme),
            Text('cloud', style: cloudTheme),
          ],
        ),
        builder: (context, child) {
          return Opacity(opacity: _controller.value, child: child);
        });
    Future.delayed(Duration(milliseconds: 10), () {
      if (widget.email != null && widget.email.isNotEmpty) {
        showLoadingDialog();
        loginBloc.loginWithGoogle(
            onSuccess: onLoginSuccess, onFailed: onLoginFailed);
      }
    });
    Timer.periodic(Duration(milliseconds: 2000), _generateRandomColor);
  }

  showLoadingDialog(){
    utils.showLoadingDialog(
        context,
        Text('Signing in',
            style: Theme.of(context)
                .textTheme
                .title
                .copyWith(color: Colors.white)));
  }

  void onLoginSuccess() {
    utils.dismissLoadingDialog(context);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  void onLoginFailed(String err) {
    utils.dismissLoadingDialog(context);
    utils.showAnimatedDialog(context, title: Text('Error'), content: Text(err));
  }

  @override
  Widget build(BuildContext context) {
    final titleTextTheme = Theme.of(context).textTheme.display3.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: Theme.of(context).textTheme.display3.fontSize - 7.0,
        color: Colors.white);

    return Scaffold(
      body: AnimatedContainer(
        height: double.infinity,
        width: double.infinity,
        duration: Duration(milliseconds: 2000),
        color: _color.withOpacity(0.5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 150.0),
              Text('Notekeeper', style: titleTextTheme),
              const SizedBox(height: 50.0),
              _animatedBuilder,
              const SizedBox(height: 50.0),
              RaisedButton.icon(
                  color: Color(0xff4285F4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  textColor: Colors.white,
                  splashColor: Color(0xffF9BD3C).withOpacity(0.7),
                  onPressed: _signInWithGoogle,
                  icon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(MyFlutterApp.google),
                  ),
                  label: Text('Sign in with Google',
                      style: Theme.of(context)
                          .textTheme
                          .subhead
                          .copyWith(color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  void _generateRandomColor(Timer timer) {
    _color = Color.fromRGBO(
        _random.nextInt(255), _random.nextInt(255), _random.nextInt(255), 1.0);
    setState(() {});
  }

  void _signInWithGoogle() {
    showLoadingDialog();
    loginBloc.loginWithGoogle(
        onSuccess: onLoginSuccess, onFailed: onLoginFailed);
  }
}
