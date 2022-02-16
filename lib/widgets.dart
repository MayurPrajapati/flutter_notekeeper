import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notekeeper/my_flutter_app_icons.dart';
import 'package:notekeeper/utils/utils.dart';

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const AnimatedText({
    Key key,
    @required this.text,
    @required this.textStyle,
  }) : super(key: key);

  @override
  _AnimatedTextState createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _textAnimation;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(curve: Curves.fastOutSlowIn, parent: _controller))
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textSize = widget.textStyle.fontSize * _textAnimation.value;

    final textStyle = widget.textStyle.copyWith(fontSize: textSize);
    return Text(widget.text, style: textStyle);
  }
}

class BottomSheetPage extends StatefulWidget {
  final int selectedColor;
  final DateTime reminderDateTime;
  final isPinned;
  final Function(int color) onColorChanged;

  const BottomSheetPage({
    Key key,
    @required this.selectedColor,
    @required this.reminderDateTime,
    @required this.isPinned,
    this.onColorChanged,
  })  : assert(isPinned != null),
        assert(selectedColor != null),
        super(key: key);

  @override
  _BottomSheetPageState createState() => _BottomSheetPageState();
}

class _BottomSheetPageState extends State<BottomSheetPage> {
  DateTime reminderDateTime;
  bool isPinned = false;
  int color;

  @override
  void initState() {
    color = widget.selectedColor;
    isPinned = widget.isPinned;
    reminderDateTime = widget.reminderDateTime;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(
            context,
            NoteData(
              color: color,
              reminder: reminderDateTime,
              isPinned: isPinned,
            ));
        return Future.value(false);
      },
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.color_lens),
            onTap: _showColorChooser,
            trailing: Container(
                decoration: BoxDecoration(
                  color: Color(widget.selectedColor),
                  shape: BoxShape.circle,
                ),
                height: 40.0,
                width: 40.0),
            title: Text('Color'),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            onTap: _showReminderChooser,
            title: Text('Reminder'),
            subtitle: reminderDateTime == null
                ? null
                : Text(formatDate(reminderDateTime)),
          ),
          ListTile(
            leading: Icon(MyFlutterApp.pin_outline),
            onTap: () {
              isPinned = !isPinned;
              setState(() {});
            },
            title: Text('Pinned'),
            trailing: Switch(
                value: isPinned,
                onChanged: (changed) {
                  print('BUILDING SWITCH $changed');
                  setState(() {
                    isPinned = changed;
                  });
                }),
          ),
        ],
      ),
    );
  }

  void _showColorChooser() async {
    color = await showModalBottomSheet<int>(
        context: context,
        builder: (context) {
          return ColorChooser(
            initialColor: color,
            onColorChanged: widget.onColorChanged,
          );
        });
  }

  void _showReminderChooser() async {
    final now = DateTime.now();
    final initialDate = reminderDateTime == null ? now : reminderDateTime;

    final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: DateTime(now.year + 1));

    final initialTime = reminderDateTime == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: reminderDateTime.hour, minute: reminderDateTime.minute);

    if (date == null) return;
    final time =
        await showTimePicker(context: context, initialTime: initialTime);
    if (time == null) return;
    final chosenDate =
        DateTime(date.year, date.month, date.day, time.hour, time.minute, 0);
    setState(() {
      reminderDateTime = chosenDate;
    });
  }
}

class NoteData {
  final int color;
  final DateTime reminder;
  final bool isPinned;

  NoteData({
    @required this.color,
    @required this.reminder,
    @required this.isPinned,
  });
}

class ColorChooser extends StatefulWidget {
  final int initialColor;
  final Function(int color) onColorChanged;

  const ColorChooser({
    Key key,
    this.initialColor,
    this.onColorChanged,
  }) : super(key: key);

  @override
  _ColorChooserState createState() => _ColorChooserState();
}

class _ColorChooserState extends State<ColorChooser> {
  int selectedColor;

  @override
  void initState() {
    selectedColor = widget.initialColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, selectedColor);
        return Future.value(false);
      },
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        children: <Widget>[
          ListTile(title: Text('Choose Color')),
          Wrap(
            direction: Axis.horizontal,
            children: colors.map((color) {
              final isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () {
                  if (selectedColor != color) widget.onColorChanged(color);
                  setState(() {
                    selectedColor = color;
                  });
                },
                child: AnimatedContainer(
                  curve: Curves.easeOutSine,
                  decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: isSelected
                          ? BorderRadius.circular(30.0)
                          : BorderRadius.circular(0.0),
                      border: isSelected
                          ? Border.all(color: Colors.black)
                          : Border.all(color: Color(color))),
                  duration: Duration(milliseconds: 500),
                  margin: EdgeInsets.all(4.0),
                  height: 60.0,
                  width: 60.0,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
