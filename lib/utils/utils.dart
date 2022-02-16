import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final colors = [
  0xffffffff,
  0xffFF5AB3,
  0xff00FF66,
  0xff00FFCC,
  0xff99CC66,
  0xff99CCFF,
  0xffFB7E81,
  0xffCCFF00,
  0xffCC99FF,
  0xffFFFF66,
  0xffFF9933,
  0xffCC9900,
  0xff9999FF,
  0xff66CC00,
  0xff00CCFF,
];

bool _isShowingLoadingDialog = false;

void showAnimatedDialog(BuildContext context,
    {Widget title, Widget content, List<Widget> actions}) {
  showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
//        final val = a1.value - 1.0;
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;

        return Transform(
//          scale: a1.value,
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              actions: actions,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: title,
              content: content,
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 200),
      // DURATION FOR ANIMATION
      barrierDismissible: true,
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return SizedBox();
      });
}

showLoadingDialog(BuildContext context, [Widget caption]) async {
  if (_isShowingLoadingDialog) return;
  _isShowingLoadingDialog = true;
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          elevation: 0.0,
          content: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(backgroundColor: Colors.white),
                SizedBox(height: 16.0),
                caption == null ? SizedBox() : caption,
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
        );
      });
  _isShowingLoadingDialog = false;
}

dismissLoadingDialog(BuildContext context) {
  if (_isShowingLoadingDialog) Navigator.pop(context);
  _isShowingLoadingDialog = false;
}


String formatDate(DateTime dateTime) =>
    DateFormat.yMMMMd().add_jm().format(dateTime);