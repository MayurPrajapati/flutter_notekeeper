import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:notekeeper/bloc/user_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notes_bloc.dart';

class LoginBloc {
  void loginWithGoogle(
      {@required void Function() onSuccess,
      @required void Function(String error) onFailed}) async {
    try {
      final google = await GoogleSignIn().signIn();
      final googleAuth = await google.authentication;
      final firebaseUser = await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.getCredential(
              idToken: googleAuth.idToken,
              accessToken: googleAuth.accessToken));
      if (firebaseUser != null) {
        final sp = await SharedPreferences.getInstance();
        sp.setString('email', firebaseUser.email);
        _initialize(firebaseUser);
        onSuccess();
      } else
        onFailed("Couldn't login");
    } catch (e) {
      if (e is PlatformException) onFailed(e.message);
      if (e is AuthException) onFailed(e.message);
    }
  }

  void _initialize(FirebaseUser fUser) {
    final user = User.instance;
    user.email = fUser.email;
    user.displayPicUrl = fUser.photoUrl;
    user.name = fUser.displayName;

    NotesBloc.instance;
  }
}
