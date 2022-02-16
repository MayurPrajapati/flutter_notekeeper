import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:notekeeper/bloc/notes_bloc.dart';
import 'package:notekeeper/bloc/user_bloc.dart';
import 'package:notekeeper/screens/reminders_screen.dart';
import 'package:notekeeper/utils/utils.dart';

class UserInfoPage extends StatelessWidget {
  final bool isSelected;
  final int animationDuration;
  final NotesBloc notesBloc;
  final user = User.instance;

  UserInfoPage(
      {Key key,
      @required this.isSelected,
      @required this.animationDuration,
      @required this.notesBloc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = Text(user.name,
        style: Theme.of(context).textTheme.headline.copyWith(
            fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.6)));

    final profile = ClipRRect(
        borderRadius: BorderRadius.circular(150.0),
        child: CachedNetworkImage(
          height: 150.0,
          width: 150.0,
          fit: BoxFit.fill,
          imageUrl: user.displayPicUrl,
        ));

    final showReminders = () {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return RemindersScreen(notesBloc: notesBloc);
      }));
    };

    final reminders = SizedBox(
        height: 50.0,
        width: double.infinity,
        child: FlatButton.icon(
          textColor: Colors.blue,
          splashColor: Colors.blue.withOpacity(0.5),
          icon: Icon(Icons.notifications),
          label: Text('Reminders',
              style: Theme.of(context)
                  .textTheme
                  .title
                  .copyWith(color: Colors.blue)),
          onPressed: showReminders,
        ));

    return AnimatedContainer(
      margin: isSelected
          ? EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0)
          : EdgeInsets.all(0.0),
      duration: Duration(milliseconds: animationDuration),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.8) : Color(0xffA1887F),
        borderRadius: BorderRadius.circular(isSelected ? 16.0 : 0.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 50.0),
          profile,
          SizedBox(height: 8.0),
          name,
          SizedBox(height: 16.0),
          reminders,
          Spacer(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Text('Notekeeper',
                        style: Theme.of(context).textTheme.title.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.4)))),
                IconButton(
                  color: Colors.red,
                  splashColor: Colors.red.withOpacity(0.5),
//                textColor: Colors.red,
//                shape: RoundedRectangleBorder(
//                    borderRadius: BorderRadius.only(
//                        bottomLeft: Radius.circular(16.0),
//                        bottomRight: Radius.circular(16.0))),
                  onPressed: () => showExitDialog(context),
                  icon: Icon(Icons.exit_to_app),
//                label: Text('Quit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showExitDialog(BuildContext context) async {
    showAnimatedDialog(context,
        title: Text('Quit?'),
        content: Text('Are you sure?\nYou want to exit?'),
        actions: [
          FlatButton(
              onPressed: () => Navigator.pop(context), child: Text('No')),
          FlatButton(
              onPressed: () => exit(0),
              child: Text('Quit'),
              textColor: Colors.red),
        ]);
  }
}
