import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notekeeper/bloc/user_bloc.dart';
import 'package:notekeeper/model/note_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notekeeper/utils/utils.dart';
import 'package:notekeeper/widgets.dart';
import 'package:zefyr/zefyr.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CreateOrEditNoteScreen extends StatefulWidget {
  final NoteModel note;

  const CreateOrEditNoteScreen({Key key, this.note}) : super(key: key);

  @override
  _CreateOrEditNoteScreenState createState() => _CreateOrEditNoteScreenState();
}

class _CreateOrEditNoteScreenState extends State<CreateOrEditNoteScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController titleTextEditingController;
  ZefyrController contentZefyrController;
  final focusNode = FocusNode();
  bool isPinned = false;

  int selectedCardColor = colors[0];
  DateTime reminderDateTime;
  String email;

  NoteModel note;

  @override
  void initState() {
    email = User.instance.email;

    note = widget.note;
    contentZefyrController = ZefyrController(NotusDocument())
      ..addListener(() {
        print(json.encode(contentZefyrController.document.toJson()));
      });
    titleTextEditingController = TextEditingController(text: '');

    if (note != null) {
      contentZefyrController =
          ZefyrController(NotusDocument.fromJson(json.decode(note.content)));
      titleTextEditingController = TextEditingController(text: note.title);
      isPinned = note.isPinned;
      selectedCardColor = note.cardColor;
      reminderDateTime = note.reminder;
    }
    super.initState();
  }

  void pop() async {
    //Adding not to the database
    final title = titleTextEditingController.text.trim();

    // Blank note
    if (contentZefyrController.plainTextEditingValue.text.trim().isEmpty &&
        title.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final database = Firestore.instance;
    NoteModel note = NoteModel(
      plainContent: contentZefyrController.document.toPlainText(),
      content: json.encode(contentZefyrController.document.toJson()),
      cardColor: selectedCardColor,
      isPinned: isPinned,
      title: title,
      reminder: reminderDateTime,
    );

    if (widget.note != null) {
      database
          .collection(email)
          .document(widget.note.id)
          .updateData(note.toJson());

      Navigator.pop(context);
      return;
    }

    database.collection(email).document().setData(note.toJson());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.title;

    return WillPopScope(
      onWillPop: () {
        pop();
        return Future.value(false);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Color(selectedCardColor),
        floatingActionButton: Align(
          alignment: FractionalOffset(1.0, 0.93),
          child: FloatingActionButton(
            onPressed: () => showNoteBottomSheet(),
            child: Icon(Icons.keyboard_arrow_up),
          ),
        ),
        appBar: AppBar(
            title: Text('Create Note', style: TextStyle(color: Colors.black)),
            elevation: 0.0,
            leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => pop()),
            backgroundColor: Colors.transparent),
        body: ZefyrScaffold(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  controller: titleTextEditingController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Title',
                      hintStyle: title.copyWith(
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Content',
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontSize: 16.0),
                      ),
                      Expanded(
                        child: Theme(
                          data: ThemeData(
                            primaryColorLight: Colors.white,
                            primaryColor: Color(0xffcccccc),
                          ),
                          child: ZefyrField(
                            imageDelegate: ImageDelegate(
                                email: email,
                                scaffoldState: _scaffoldKey.currentState),
                            decoration:
                                InputDecoration(border: InputBorder.none),
                            controller: contentZefyrController,
                            focusNode: focusNode,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void updateColor(int color) {
    setState(() {
      selectedCardColor = color;
    });
  }

  void showNoteBottomSheet() async {
    final data = await showModalBottomSheet<NoteData>(
        context: context,
        builder: (context) {
          return BottomSheetPage(
            isPinned: isPinned,
            selectedColor: selectedCardColor,
            reminderDateTime: reminderDateTime,
            onColorChanged: (int color) {
              setState(() {
                selectedCardColor = color;
              });
            },
          );
        });

    if (reminderDateTime != data.reminder) reminderDateTime = data.reminder;
    if (isPinned != data.isPinned) isPinned = data.isPinned;
    if (selectedCardColor != data.color) selectedCardColor = data.color;
  }

  void onReminderDateChanged(DateTime dateTime) {
    reminderDateTime = dateTime;
  }

  void onIsPinnedStateChanged(bool changed) {
    isPinned = changed;
    print('PINNED CHANGED TO $changed');
  }
}

class ImageDelegate extends ZefyrImageDelegate<ImageSource> {
  final String email;
  final ScaffoldState scaffoldState;

  ImageDelegate({this.email, @required this.scaffoldState});

  @override
  Widget buildImage(BuildContext context, String imageSource) {
    return GestureDetector(
      onTap: () {
        print('TAPPED');
      },
      child: CachedNetworkImage(
        imageUrl: imageSource,
        placeholder: (context, msg) => CircularProgressIndicator(),
        errorWidget: (context, error, obj) {
          return Center(
            child: IconButton(icon: Icon(Icons.refresh), onPressed: () {}),
          );
        },
      ),
    );
  }

  @override
  Future<String> pickImage(source) async {
    final image = await ImagePicker.pickImage(
      source: source,
      maxHeight: 280,
      maxWidth: 440,
    );

    if (image == null) return null;
    final uploadTask = FirebaseStorage.instance
        .ref()
        .child(email)
        .child('${getImageName(image.path)}')
        .putFile(image);

    final intStream = StreamController<int>();

    final controller = scaffoldState.showSnackBar(
      SnackBar(
        duration: Duration(days: 365),
        content: StreamBuilder<int>(
            initialData: 0,
            stream: intStream.stream,
            builder: (context, snapshot) {
              return Row(
                children: <Widget>[
                  Text('Uploading'),
                  const SizedBox(width: 12.0),
                  Text('${snapshot.data} %',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              );
            }),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {
            uploadTask.cancel();
          },
          textColor: Colors.red,
        ),
      ),
    );

    uploadTask.events.listen((event) {
      int percentage = event.snapshot.bytesTransferred *
          100 ~/
          event.snapshot.totalByteCount;

      intStream.add(percentage);
    });

    final snapshot = await uploadTask.onComplete;
    if (uploadTask.isSuccessful && uploadTask.isComplete) {
      String url = await snapshot.ref.getDownloadURL();
      controller.close();
      intStream.close();
      return url;
    }
    controller.close();
    intStream.close();
    return null;
  }

  String getImageName(String path) {
    return path.substring(path.lastIndexOf('/'));
  }
}
