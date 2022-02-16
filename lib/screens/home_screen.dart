import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:notekeeper/model/note_model.dart';
import 'package:notekeeper/my_flutter_app_icons.dart';
import 'package:notekeeper/screens/create_or_edit_note_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:notekeeper/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:notekeeper/bloc/notes_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notekeeper/widgets.dart';
import 'package:zefyr/zefyr.dart';

import 'user_info_page.dart';

class HomeScreen extends StatelessWidget {
  final NotesBloc noteBloc = NotesBloc.instance;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    return WillPopScope(
      onWillPop: () async {
        showExitDialog(context);
        return false;
      },
      child: _Body(notesBloc: noteBloc),
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

class _Body extends StatefulWidget {
  final NotesBloc notesBloc;

  const _Body({Key key, @required this.notesBloc}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static bool isPinnedNotesSelectionModeOn = false;
  static bool isNormalNotesSelectionModeOn = false;

  static int selectedPinnedNotesCount = 0;
  static int selectedNormalNotesCount = 0;

  final PageController _pageController = PageController(viewportFraction: 0.90);
  NotesBloc notesBloc;
  final _animationDuration = 300;
  int _selectedPage = 0;

  Widget pinnedNotesStreamBuilder;

  Widget normalNotesStreamBuilder;

  bool isShowingPinnedNotesBottomAppBar = false;
  bool isShowingNormalNotesBottomAppBar = false;

  List<NoteValueChangeNotifier> pinnedNotes = [];

  List<NoteValueChangeNotifier> normalNotes = [];

  @override
  void initState() {
    notesBloc = widget.notesBloc;
    _pageController.addListener(() {
      final page = _pageController.page.round();
      if (_selectedPage != page) {
        setState(() {
          _selectedPage = page;
        });
      }
    });

    normalNotesStreamBuilder =
        StreamBuilder<Map<String, NoteValueChangeNotifier>>(
      stream: notesBloc.normalNotesStream.asBroadcastStream(),
      initialData: notesBloc.normalNotesValueNotifiers,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return SizedBox();

        normalNotes = snapshot.data.values.toList();

        final List<StaggeredTile> tiles = [
          StaggeredTile.fit(2),
          StaggeredTile.fit(2),
          StaggeredTile.fit(2),
          StaggeredTile.fit(2),
        ];

        final List<Widget> children = [
          SizedBox(height: 100.0),
          SizedBox(height: 100.0),
        ];

        for (int i = 0; i < normalNotes.length; i++) {
          tiles.add(StaggeredTile.fit(2));
          children.add(_buildNote(normalNotes, i));
        }

        children..add(SizedBox(height: 100.0))..add(SizedBox(height: 100.0));

        return Center(
          child: normalNotes.length > 0
              ? StaggeredGridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.all(2.0),
                  children: children,
                  staggeredTiles: tiles,
                  mainAxisSpacing: 3.0,
                  crossAxisSpacing: 4.0,
                  physics: BouncingScrollPhysics(),
                )
              : Text('No notes', style: TextStyle(color: Colors.white)),
        );
      },
    );

    pinnedNotesStreamBuilder =
        StreamBuilder<Map<String, NoteValueChangeNotifier>>(
      stream: notesBloc.pinnedNotesStream,
      initialData: notesBloc.pinnedNotesValueNotifiers,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return SizedBox();

        print('BUILDING PINNED');

        pinnedNotes = snapshot.data.values.toList();

        final List<StaggeredTile> tiles = [
          StaggeredTile.fit(2),
          StaggeredTile.fit(2),
          StaggeredTile.fit(2),
          StaggeredTile.fit(2),
        ];

        final List<Widget> children = [
          SizedBox(height: 100.0),
          SizedBox(height: 100.0)
        ];
        for (int i = 0; i < pinnedNotes.length; i++) {
          tiles.add(StaggeredTile.fit(2));
          children.add(_buildNote(pinnedNotes, i));
        }

        children..add(SizedBox(height: 100.0))..add(SizedBox(height: 100.0));

        return Center(
          child: pinnedNotes.length > 0
              ? StaggeredGridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.all(2.0),
                  children: children,
                  staggeredTiles: tiles,
                  mainAxisSpacing: 3.0,
                  crossAxisSpacing: 4.0,
                  physics: BouncingScrollPhysics(),
                )
              : Text('No pinned notes', style: TextStyle(color: Colors.white)),
        );
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffA1887F),
      body: PageView(
        children: <Widget>[
          _buildPage(context, 0),
          _buildPage(context, 1),
          _buildPage(context, 2),
        ],
        controller: _pageController,
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  void _onClickFAB(BuildContext context) async {
    clearSelection(isPinned: true);
    clearSelection(isPinned: false);

    Navigator.push(context,
        MaterialPageRoute(builder: (context) => CreateOrEditNoteScreen()));
  }

  void clearSelection({@required bool isPinned}) {
    if (isPinned) {
      if (isShowingPinnedNotesBottomAppBar) {
        notesBloc.clearSelection(isPinned: true);
        isShowingPinnedNotesBottomAppBar = false;
        isPinnedNotesSelectionModeOn = false;
        selectedPinnedNotesCount = 0;

        setState(() {});
      }
    } else {
      if (isShowingNormalNotesBottomAppBar) {
        notesBloc.clearSelection(isPinned: false);
        isShowingNormalNotesBottomAppBar = false;
        isNormalNotesSelectionModeOn = false;
        selectedNormalNotesCount = 0;

        setState(() {});
      }
    }
  }

  Future<int> _showColorChooser(void Function(int color) onColorChanged) async {
    return await showModalBottomSheet<int>(
        context: context,
        builder: (context) {
          return ColorChooser(
            initialColor: -1,
            onColorChanged: onColorChanged,
          );
        });
  }

  Future<DateTime> _showReminderChooser() async {
    final now = DateTime.now();
    final initialDate = now;

    final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: DateTime(now.year + 1));

    final initialTime = TimeOfDay.now();

    if (date == null) return null;
    final time =
        await showTimePicker(context: context, initialTime: initialTime);
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute, 0);
  }

  Widget _buildPage(BuildContext context, int index) {
    final iconColor = Theme.of(context).primaryColor;

    if (index == 0) return _buildUserInfoPage(_selectedPage == 0);
    if (index == 1) {
      final onClearButtonClicked = () async {
        clearSelection(isPinned: true);
      };

      final onDeleteButtonClicked = () {
        showAnimatedDialog(
          context,
          actions: <Widget>[
            FlatButton(
                child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
            RaisedButton(
                textColor: Colors.white,
                color: Colors.red,
                child: Text('Delete'),
                onPressed: () {
                  Navigator.of(context).pop();
                  notesBloc.deleteSelectedNotes(isPinned: true);
                  clearSelection(isPinned: true);
                }),
          ],
          title: Text('Confirm?'),
          content: Text('Delete selected notes?\nThis cannot be undone.'),
        );
      };

      final onColorButtonClicked = () async {
        final onColorChanged = (int color) {
          Navigator.pop(context);
          notesBloc.changeColor(isPinned: true, newColor: color);
          print('CLEARING SELECTION');
          clearSelection(isPinned: true);
        };

        _showColorChooser(onColorChanged);
      };

      final onChangePinnedStateClicked = () {
        notesBloc.changePinnedState(isPinned: true);
        clearSelection(isPinned: true);
      };

      final onChangeReminderClicked = () async {
        final date = await _showReminderChooser();
        if (date != null) {
          await notesBloc.changeReminder(isPinned: true, newReminder: date);
          clearSelection(isPinned: true);
        }
      };

      final bottomAppBar = isShowingPinnedNotesBottomAppBar
          ? SizedBox(
              height: 60.0,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                elevation: 8.0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: onClearButtonClicked),
                      SizedBox(width: 8.0),
                      AnimatedText(
                        key: UniqueKey(),
                        text: '$selectedPinnedNotesCount',
                        textStyle: TextStyle(fontSize: 20.0),
                      ),
                      Spacer(),
                      IconButton(
                          icon: Icon(Icons.color_lens, color: iconColor),
                          onPressed: onColorButtonClicked),
                      IconButton(
                          icon:
                              Icon(MyFlutterApp.pin_outline, color: iconColor),
                          onPressed: onChangePinnedStateClicked),
                      IconButton(
                          icon: Icon(Icons.notifications, color: iconColor),
                          onPressed: onChangeReminderClicked),
                      IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: onDeleteButtonClicked),
                    ],
                  ),
                ),
              ),
            )
          : SizedBox();

      return Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                _buildPinnedNotes(_selectedPage == 1),
                Align(
                    alignment: FractionalOffset(0.5, 0.97),
                    child: bottomAppBar),
              ],
            ),
          ),
        ],
      );
    }
    if (index == 2) {
      final onClearButtonClicked = () async {
        clearSelection(isPinned: false);
      };

      final onDeleteButtonClicked = () {
        showAnimatedDialog(
          context,
          actions: <Widget>[
            FlatButton(
                child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
            RaisedButton(
                textColor: Colors.white,
                color: Colors.red,
                child: Text('Delete'),
                onPressed: () {
                  Navigator.pop(context);
                  notesBloc.deleteSelectedNotes(isPinned: false);
                  clearSelection(isPinned: false);
                }),
          ],
          title: Text('Confirm?'),
          content: Text('Delete selected notes?\nThis cannot be undone.'),
        );
      };

      final onColorButtonClicked = () async {
        final onColorChanged = (int color) {
          Navigator.pop(context);
          notesBloc.changeColor(isPinned: false, newColor: color);
          clearSelection(isPinned: false);
        };

        _showColorChooser(onColorChanged);
      };

      final onChangePinnedStateClicked = () {
        notesBloc.changePinnedState(isPinned: false);
        clearSelection(isPinned: false);
      };

      final onChangeReminderClicked = () async {
        final date = await _showReminderChooser();
        if (date != null) {
          await notesBloc.changeReminder(isPinned: false, newReminder: date);
          clearSelection(isPinned: false);
        }
      };

      final bottomAppBar = isShowingNormalNotesBottomAppBar
          ? SizedBox(
              height: 60.0,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                elevation: 8.0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: onClearButtonClicked),
                      SizedBox(width: 8.0),
                      AnimatedText(
                        key: UniqueKey(),
                        text: '$selectedNormalNotesCount',
                        textStyle: TextStyle(fontSize: 20.0),
                      ),
                      Spacer(),
                      IconButton(
                          icon: Icon(Icons.color_lens, color: iconColor),
                          onPressed: onColorButtonClicked),
                      IconButton(
                          icon: Icon(MyFlutterApp.pin, color: iconColor),
                          onPressed: onChangePinnedStateClicked),
                      IconButton(
                          icon: Icon(Icons.notifications, color: iconColor),
                          onPressed: onChangeReminderClicked),
                      IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: onDeleteButtonClicked),
                    ],
                  ),
                ),
              ),
            )
          : SizedBox();

      return Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                _buildNormalNotes(_selectedPage == 2),
                Align(
                    alignment: FractionalOffset(0.5, 0.97),
                    child: bottomAppBar),
              ],
            ),
          ),
        ],
      );
    }

    throw UnimplementedError();
  }

  Widget _buildUserInfoPage(bool isSelected) {
    return UserInfoPage(
        notesBloc: notesBloc,
        key: Key('USERPAGE'),
        isSelected: isSelected,
        animationDuration: _animationDuration);
  }

  Widget _buildPinnedNotes(bool isSelected) {
    final textTheme = Theme.of(context).textTheme.display2;
    final color = Colors.white;
    final textStyle = isSelected
        ? textTheme.copyWith(color: color, fontWeight: FontWeight.bold)
        : textTheme.copyWith(
            color: color.withOpacity(0.7),
            fontSize: textTheme.fontSize - 8.0,
            fontWeight: FontWeight.bold);
    final margin = isSelected ? EdgeInsets.all(0.0) : EdgeInsets.all(8.0);

    return AnimatedContainer(
      duration: Duration(milliseconds: _animationDuration),
      margin: margin,
      child: Stack(
        children: <Widget>[
          pinnedNotesStreamBuilder,
          Container(
            color: Color(0xffA1887F).withOpacity(0.65),
            child: Row(
              children: <Widget>[
                const Spacer(),
                Text('Pinned', style: textStyle),
                const SizedBox(width: 8.0),
              ],
            ),
          ),
        ],
      ),
//      color: Colors.orange,
    );
  }

  Widget _buildNote(List<NoteValueChangeNotifier> notes, int pos) {
    final note = notes[pos];

    final onLongPress = () {
      print('LONG PRESS');
    };

    final onTap = () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CreateOrEditNoteScreen(note: note.value)));
    };

    return NoteWidget(
      key: ObjectKey(note),
      onNoteSelectionChanged: toggleBottomAppBar,
      onTap: onTap,
      note: note,
      onLongPress: onLongPress,
    );
  }

  void toggleBottomAppBar(bool show, bool isPinned) {
    print('SELECTION CHANGED: show?: $show isPinned: $isPinned');
    if (isPinned) {
      if (show) {
        setState(() {
          isShowingPinnedNotesBottomAppBar = true;
        });
      } else {
        setState(() {
          isShowingPinnedNotesBottomAppBar = false;
        });
      }
    } else {
      if (show) {
        setState(() {
          isShowingNormalNotesBottomAppBar = true;
        });
      } else {
        setState(() {
          isShowingNormalNotesBottomAppBar = false;
        });
      }
    }
  }

  Widget _buildNormalNotes(bool isSelected) {
    final textTheme = Theme.of(context).textTheme.display2;
    final color = Colors.white;
    final textStyle = isSelected
        ? textTheme.copyWith(color: color, fontWeight: FontWeight.bold)
        : textTheme.copyWith(
            color: color.withOpacity(0.7),
            fontSize: textTheme.fontSize - 8.0,
            fontWeight: FontWeight.bold);
    final margin = isSelected ? EdgeInsets.all(0.0) : EdgeInsets.all(8.0);

    return AnimatedContainer(
      duration: Duration(milliseconds: _animationDuration),
      margin: margin,
      child: Stack(
        children: <Widget>[
          normalNotesStreamBuilder,
          Container(
            color: Color(0xffA1887F).withOpacity(0.65),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 8.0),
                Text('Notes', style: textStyle),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
//      color: Colors.orange,
    );
  }

  Widget _buildFAB() {
    if (_selectedPage == 0) return null;

//    final onClickSearchButton = () {};

    if (_selectedPage == 1 && isPinnedNotesSelectionModeOn) return null;
    if (_selectedPage == 2 && isNormalNotesSelectionModeOn) return null;

    return Wrap(
      direction: Axis.vertical,
      children: <Widget>[
//        SizedBox(
//            height: 45.0,
//            child: FloatingActionButton(
//                backgroundColor: Colors.white,
//                onPressed: onClickSearchButton,
//                child: Icon(Icons.search, color: Colors.black))),
//        SizedBox(height: 16.0),
        FloatingActionButton(
            onPressed: () => _onClickFAB(context), child: Icon(Icons.add)),
      ],
    );
  }
}

class NoteWidget extends StatefulWidget {
  final NoteValueChangeNotifier note;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final void Function(bool show, bool isPinned) onNoteSelectionChanged;

  const NoteWidget({
    Key key,
    @required this.note,
    @required this.onLongPress,
    @required this.onTap,
    @required this.onNoteSelectionChanged,
  }) : super(key: key);

  @override
  _NoteWidgetState createState() => _NoteWidgetState();
}

class _NoteWidgetState extends State<NoteWidget> {
  NoteModel note;

  @override
  void initState() {
    note = widget.note.value;
    widget.note.addListener(listener);
    super.initState();
  }

  void listener() {
    print('REBUILDING NOTE WIDGET');
    setState(() {
      note = widget.note.value;
      print('IS SELECTED: ${note.isSelected}');
    });
  }

  @override
  void dispose() {
    widget.note.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = note.title.isNotEmpty
        ? Text(note.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 23.0,
            ))
        : SizedBox();

    final content = IgnorePointer(
        ignoring: true,
        child: ZefyrView(
          document: NotusDocument.fromJson(json.decode(note.content)),
          imageDelegate: ImageDelegate(scaffoldState: Scaffold.of(context)),
        ));

    final radius = BorderRadius.circular(8.0);

    final onTap = () {
      if (note.isPinned) {
        if (note.isSelected) {
          setState(() {
            note.isSelected = false;
          });

          --_BodyState.selectedPinnedNotesCount;

          if (_BodyState.selectedPinnedNotesCount == 0) {
            _BodyState.isPinnedNotesSelectionModeOn = false;
            widget.onNoteSelectionChanged(false, true);
          } else
            widget.onNoteSelectionChanged(true, true);
          return;
        } else if (_BodyState.isPinnedNotesSelectionModeOn) {
          widget.onNoteSelectionChanged(true, true);
          ++_BodyState.selectedPinnedNotesCount;
          setState(() {
            note.isSelected = true;
          });
          return;
        }
      } else {
        //It's not a pinned note
        if (note.isSelected) {
          setState(() {
            note.isSelected = false;
          });

          --_BodyState.selectedNormalNotesCount;

          if (_BodyState.selectedNormalNotesCount == 0) {
            _BodyState.isNormalNotesSelectionModeOn = false;
            widget.onNoteSelectionChanged(false, false);
          } else
            widget.onNoteSelectionChanged(true, false);

          return;
        } else if (_BodyState.isNormalNotesSelectionModeOn) {
          ++_BodyState.selectedNormalNotesCount;
          widget.onNoteSelectionChanged(true, false);
          setState(() {
            note.isSelected = true;
          });
          return;
        }
      }
      widget.onTap();
    };

    final onLongPress = () {
      if (note.isPinned) {
        _BodyState.isPinnedNotesSelectionModeOn = true;

        if (note.isSelected) {
          setState(() {
            note.isSelected = false;
          });

          --_BodyState.selectedPinnedNotesCount;

          if (_BodyState.selectedPinnedNotesCount == 0) {
            _BodyState.isPinnedNotesSelectionModeOn = false;
            widget.onNoteSelectionChanged(false, true);
          } else {
            widget.onNoteSelectionChanged(true, true);
          }

          return;
        } else if (_BodyState.isPinnedNotesSelectionModeOn) {
          ++_BodyState.selectedPinnedNotesCount;
          setState(() {
            note.isSelected = true;
          });
          widget.onNoteSelectionChanged(true, true);
          return;
        }
      } else {
        _BodyState.isNormalNotesSelectionModeOn = true;

        if (note.isSelected) {
          setState(() {
            note.isSelected = false;
          });

          --_BodyState.selectedNormalNotesCount;

          if (_BodyState.selectedNormalNotesCount == 0) {
            _BodyState.isNormalNotesSelectionModeOn = false;
            widget.onNoteSelectionChanged(false, false);
          } else
            widget.onNoteSelectionChanged(true, false);
          return;
        } else if (_BodyState.isNormalNotesSelectionModeOn) {
          ++_BodyState.selectedNormalNotesCount;
          setState(() {
            note.isSelected = true;
          });
          widget.onNoteSelectionChanged(true, false);
          return;
        }
      }
      widget.onLongPress();
    };

    final data = Card(
      key: ObjectKey(note),
      elevation: 4.0,
      color: Color(note.cardColor),
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        borderRadius: radius,
        splashColor: Colors.amber,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                content,
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedContainer(
      constraints: BoxConstraints(maxHeight: 500.0),
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: 4.0),
      curve: Curves.ease,
      child: data,
      foregroundDecoration: BoxDecoration(
        border: Border.all(
            color: note.isSelected ? Color(note.cardColor) : Colors.transparent,
            width: 1.5),
        color: note.isSelected
            ? Colors.black.withOpacity(0.23)
            : Colors.transparent,
        borderRadius: radius,
      ),
    );
  }
}
