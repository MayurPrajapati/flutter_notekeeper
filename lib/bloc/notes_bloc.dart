import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notekeeper/bloc/user_bloc.dart';
import 'package:notekeeper/model/note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:notekeeper/main.dart';

class NotesBloc {
  var database = Firestore.instance..settings(persistenceEnabled: true);
  String email = User.instance.email;

  static NotesBloc _instance;

  final Map<String, NoteValueChangeNotifier> pinnedNotesValueNotifiers = Map();
  final Map<String, NoteValueChangeNotifier> normalNotesValueNotifiers = Map();

  Stream<Map<String, NoteValueChangeNotifier>> pinnedNotesStream;
  Stream<Map<String, NoteValueChangeNotifier>> normalNotesStream;

  final StreamController<Map<String, NoteValueChangeNotifier>>
      pinnedNoteStreamController = StreamController();

  final StreamController<Map<String, NoteValueChangeNotifier>>
      normalNoteStreamController = StreamController();

  NotesBloc._() {
    pinnedNotesStream = pinnedNoteStreamController.stream.asBroadcastStream();
    normalNotesStream = normalNoteStreamController.stream.asBroadcastStream();
    initialize();
  }

  void dispose() {
    pinnedNoteStreamController.close();
    normalNoteStreamController.close();
  }

  static NotesBloc get instance {
    if (_instance == null) _instance = NotesBloc._();
    return _instance;
  }

  void initialize() async {
    final snapshots = database
        .collection(email)
        .orderBy('addedDate', descending: true)
        .snapshots();

    snapshots.listen((snap) {
      final tempNormalNotes = Map<String, NoteValueChangeNotifier>();
      final tempPinnedNotes = Map<String, NoteValueChangeNotifier>();

      snap.documents.forEach((doc) {
        if (doc['content'] == null ||
            doc['addedDate'] == null ||
            doc['id'] == null ||
            doc['cardColor'] == null ||
            doc['isPinned'] == null) return;

        final note = NoteModel.fromSnapshot(doc);

        if (note.isPinned) {
          final value = pinnedNotesValueNotifiers[note.id];

          if (value != null) {
            value.value = note;
          }

          tempPinnedNotes[note.id] = NoteValueChangeNotifier(note);
        } else {
          final value = normalNotesValueNotifiers[note.id];

          if (value != null) {
            value.value = note;
          }

          tempNormalNotes[note.id] = NoteValueChangeNotifier(note);
        }
      });

      scheduleNotifications();

      // length will be not equal in case of note addition and deletion
      if (tempNormalNotes.values.length > 0) {
        if (tempNormalNotes.values.length !=
            normalNotesValueNotifiers.values.length) {
          normalNoteStreamController.add(tempNormalNotes);
        }
      }

      if (tempPinnedNotes.values.length > 0) {
        if (tempPinnedNotes.values.length !=
            pinnedNotesValueNotifiers.values.length) {
          pinnedNoteStreamController.add(tempPinnedNotes);
        }
      }

      pinnedNotesValueNotifiers
        ..clear()
        ..addAll(tempPinnedNotes);
      normalNotesValueNotifiers
        ..clear()
        ..addAll(tempNormalNotes);
    });
  }

  void clearSelection({@required bool isPinned}) {
    if (isPinned) {
      pinnedNotesValueNotifiers.values.forEach((value) {
        value.value.isSelected = false;
      });
      pinnedNoteStreamController.add(pinnedNotesValueNotifiers);
    } else {
      normalNotesValueNotifiers.values.forEach((value) {
        value.value.isSelected = false;
      });
      normalNoteStreamController.add(normalNotesValueNotifiers);
    }
  }

  void changePinnedState({@required bool isPinned}) {
    if (isPinned) {
      final batch = database.batch();

      final Map<String, NoteValueChangeNotifier> temp =
          Map.from(pinnedNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;
        if (note.isSelected) {
          batch.updateData(note.ref, {
            'isPinned': false,
            'addedDate': FieldValue.serverTimestamp(),
          });
          normalNotesValueNotifiers[value.value.id] =
              pinnedNotesValueNotifiers.remove(value.value.id)
                ..value.isPinned = false
                ..value.isSelected = false;
        }
      });
      batch.commit();
    } else {
      final batch = database.batch();
      final temp = Map.from(normalNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;
        if (note.isSelected) {
          batch.updateData(note.ref, {
            'isPinned': true,
            'addedDate': FieldValue.serverTimestamp(),
          });

          pinnedNotesValueNotifiers[value.value.id] =
              normalNotesValueNotifiers.remove(value.value.id)
                ..value.isPinned = false
                ..value.isSelected = false;
        }
      });
      normalNoteStreamController.add(normalNotesValueNotifiers);
      pinnedNoteStreamController.add(pinnedNotesValueNotifiers);
      batch.commit();
    }
  }

  Future<void> changeColor(
      {@required bool isPinned, @required int newColor}) async {
    if (isPinned) {
      final batch = database.batch();

      final Map<String, NoteValueChangeNotifier> temp =
          Map.from(pinnedNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;
        if (note.isSelected) {
          if (note.cardColor == newColor) return;
          batch.updateData(note.ref, {
            'cardColor': newColor,
            'addedDate': FieldValue.serverTimestamp(),
          });

          pinnedNotesValueNotifiers[value.value.id].value = value.value
            ..cardColor = newColor;
        }
      });

      batch.commit();
    } else {
      final batch = database.batch();

      final Map<String, NoteValueChangeNotifier> temp =
          Map.from(normalNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;
        if (note.isSelected) {
          if (note.cardColor == newColor) return;
          batch.updateData(note.ref, {
            'cardColor': newColor,
            'addedDate': FieldValue.serverTimestamp(),
          });

          normalNotesValueNotifiers[value.value.id].value = value.value
            ..cardColor = newColor;
        }
      });

      batch.commit();
    }
  }

  Future<void> changeReminder(
      {@required bool isPinned, @required DateTime newReminder}) async {
    if (isPinned) {
      final batch = database.batch();

      final Map<String, NoteValueChangeNotifier> temp =
          Map.from(pinnedNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;
        if (note.isSelected) {
          if (note.reminder == newReminder) return;

          if (note.reminder != null)
            notifications.cancel(generateId(note.reminder));

          batch.updateData(note.ref, {
            'reminder': Timestamp.fromDate(newReminder),
            'addedDate': FieldValue.serverTimestamp(),
          });

          pinnedNotesValueNotifiers[value.value.id].value = value.value
            ..reminder = newReminder;
        }
      });

      scheduleNotifications();
      batch.commit();
    } else {
      final batch = database.batch();

      final Map<String, NoteValueChangeNotifier> temp =
          Map.from(normalNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;
        if (note.isSelected) {
          if (note.reminder != null)
            notifications.cancel(generateId(note.reminder));

          if (note.reminder == newReminder) return;

          batch.updateData(note.ref, {
            'reminder': Timestamp.fromDate(newReminder),
            'addedDate': FieldValue.serverTimestamp(),
          });

          normalNotesValueNotifiers[value.value.id].value = value.value
            ..reminder = newReminder;
        }
      });

      scheduleNotifications();

      batch.commit();
    }
  }

  void deleteSelectedNotes({@required bool isPinned}) {
    if (isPinned) {
      final batch = database.batch();

      final temp = Map.from(pinnedNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;

        if (note.isSelected) {
          batch.delete(note.ref);
          pinnedNotesValueNotifiers.remove(value.value.id);
        }
      });
      pinnedNoteStreamController.add(pinnedNotesValueNotifiers);
      batch.commit();
    } else {
      final batch = database.batch();

      final temp = Map.from(normalNotesValueNotifiers);

      temp.values.forEach((value) {
        final note = value.value;

        if (note.isSelected) {
          batch.delete(note.ref);
          normalNotesValueNotifiers.remove(value.value.id);
        }
      });
      normalNoteStreamController.add(normalNotesValueNotifiers);
      batch.commit();
    }
  }

  void scheduleNotifications() async {
    final pending = await notifications.pendingNotificationRequests();

    pinnedNotesValueNotifiers.values.forEach((value) {
      final note = value.value;

      if (note.reminder == null || note.reminder.isBefore(DateTime.now()))
        return;

      final id = generateId(note.reminder);

      PendingNotificationRequest pendingNotification;

      pendingNotification = pending.firstWhere((notification) {
        return notification.id == id;
      }, orElse: () {
        pendingNotification = null;
      });

      if (pendingNotification == null) {
        final title = note.title.isEmpty ? 'Pinned Note' : note.title;
        final body = note.title.isEmpty ? 'Pinned Note' : note.plainContent;

        notifications.schedule(
            id,
            title,
            body,
            note.reminder,
            NotificationDetails(
                AndroidNotificationDetails('random', 'random', 'random'),
                IOSNotificationDetails()));
      }
    });

    normalNotesValueNotifiers.values.forEach((value) {
      final note = value.value;
      if (note.reminder == null || note.reminder.isBefore(DateTime.now()))
        return;

      final id = generateId(note.reminder);

      PendingNotificationRequest pendingNotification;

      pendingNotification = pending.firstWhere((notification) {
        return notification.id == id;
      }, orElse: () {
        pendingNotification = null;
      });

      if (pendingNotification == null) {
        final title = note.title.isEmpty ? 'Pinned Note' : note.title;
        final body = note.title.isEmpty ? 'Pinned Note' : note.plainContent;

        notifications.schedule(
            id,
            title,
            body,
            note.reminder,
            NotificationDetails(
                AndroidNotificationDetails('random', 'random', 'random'),
                IOSNotificationDetails()));
      }
    });
  }

  int generateId(DateTime dateTime) {
    return int.parse(
        '${dateTime.day}${dateTime.month}${dateTime.year.toString().substring(2, 4)}${dateTime.hour}${dateTime.minute}');
  }
}
