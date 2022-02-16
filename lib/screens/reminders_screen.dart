import 'package:flutter/material.dart';
import 'package:notekeeper/bloc/notes_bloc.dart';
import 'package:notekeeper/utils/utils.dart';
import 'create_or_edit_note_screen.dart';

class RemindersScreen extends StatefulWidget {
  final NotesBloc notesBloc;

  const RemindersScreen({Key key, @required this.notesBloc}) : super(key: key);

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    widget.notesBloc.pinnedNotesStream.listen((data) {
      setState(() {});
    });
    widget.notesBloc.normalNotesStream.listen((data) {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reminders')),
      body: _buildRemindersList(context),
    );
  }

  Widget _buildRemindersList(BuildContext context) {
    int count = 0;

    final pinnedReminders =
        widget.notesBloc.pinnedNotesValueNotifiers.values.where((value) {
      final note = value.value;
      return note.reminder != null && note.reminder.isAfter(DateTime.now());
    }).toList();

    final normalReminders =
        widget.notesBloc.normalNotesValueNotifiers.values.where((value) {
      final note = value.value;
      return note.reminder != null && note.reminder.isAfter(DateTime.now());
    }).toList();

    final List<Widget> children = [];

    if (pinnedReminders != null && pinnedReminders.isNotEmpty) {
      final pinnedWidget = pinnedReminders.map<Widget>((value) {
        final note = value.value;
        return ListTile(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CreateOrEditNoteScreen(note: note))),
          leading: Text('# ${++count}'),
          subtitle: Text(formatDate(note.reminder)),
          title:
              note.title.isEmpty ? Text(note.plainContent) : Text(note.title),
        );
      }).toList();

      children.addAll(pinnedWidget);
    }

    if (normalReminders != null && normalReminders.isNotEmpty) {
      final normalWidget = normalReminders.map<Widget>((value) {
        final note = value.value;

        return ListTile(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CreateOrEditNoteScreen(note: note))),
          leading: Text('# ${++count}'),
          subtitle: Text(formatDate(note.reminder)),
          title:
              note.title.isEmpty ? Text(note.plainContent) : Text(note.title),
        );
      }).toList();

      children.addAll(normalWidget);
    }

    if (children.isEmpty)
      return Center(
        child: Text('No reminders found'),
      );
    else
      return ListView(
        children: children,
      );
  }
}
