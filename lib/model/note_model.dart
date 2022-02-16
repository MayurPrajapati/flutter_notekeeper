import 'package:meta/meta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteModel {
  bool isSelected = false;

  String title;
  String id;

  ///can not be null
  String content;
  String plainContent;

  ///null in case of no notification is scheduled
  DateTime reminder;
  bool isPinned;
  DateTime addedDate = DateTime.now();
  int cardColor;

  DocumentReference ref;

  ///initialized if data arrived from firebase
//  String uid;

  NoteModel(
      {this.title = '',
      this.plainContent = '',
      this.content,
      this.reminder,
      this.isPinned = false,
      @required this.cardColor});

  Map<String, dynamic> toJson() {
    return {
      'isPinned': isPinned,
      'title': title,
      'plainContent': plainContent,
      'content': content,
      'reminder': reminder != null ? Timestamp.fromDate(reminder) : null,
      'cardColor': cardColor,
      'addedDate': FieldValue.serverTimestamp(),
    };
  }

  NoteModel.fromSnapshot(DocumentSnapshot doc) {
    ref = doc.reference;
    final addedDateTimeStamp = doc['addedDate'] as Timestamp;
    if (doc['reminder'] != null) {
      final reminderTimeStamp = doc['reminder'] as Timestamp;
      reminder = reminderTimeStamp.toDate();
    }
    plainContent = doc['plainContent'];
    addedDate = addedDateTimeStamp.toDate();
    cardColor = doc['cardColor'];
    isPinned = doc['isPinned'];
    content = doc['content'];
    id = doc['id'];
    title = doc['title'];
  }
}

class NoteValueChangeNotifier implements ValueNotifier<NoteModel> {
  NoteValueChangeNotifier(this._value);

  NoteModel _value;

  @override
  NoteModel get value {
    return _value;
  }

  List<VoidCallback> listeners = [];

  @override
  void addListener(listener) {
    if (listeners.contains(listener)) return;
    listeners.add(listener);
  }

  @override
  void dispose() {
    listeners.clear();
  }

  @override
  bool get hasListeners => listeners.length > 0;

  @override
  void notifyListeners() {
    listeners.forEach((l) => l());
  }

  @override
  void removeListener(listener) {
    listeners.remove(listener);
  }

  @override
  set value(NoteModel newValue) {
    if (_value == null ||
        _value.isPinned != newValue.isPinned ||
        _value.title != newValue.title ||
        _value.plainContent != newValue.plainContent ||
        _value.reminder != newValue.reminder ||
        _value.cardColor != newValue.cardColor ||
        _value.addedDate != newValue.addedDate) {
      _value = newValue;
      notifyListeners();
    }
  }
}
