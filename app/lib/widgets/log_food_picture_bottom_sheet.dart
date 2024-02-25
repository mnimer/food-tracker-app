import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LogFoodPictureBottomSheet extends StatefulWidget {
  const LogFoodPictureBottomSheet({super.key});

  @override
  State<LogFoodPictureBottomSheet> createState() => _LogFoodPictureBottomSheetState();
}

class _LogFoodPictureBottomSheetState extends State<LogFoodPictureBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final nameFieldController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  final firestore = FirebaseFirestore.instance;
  final storageRef = FirebaseStorage.instance.ref();
  XFile? selectedImage;

  void saveImage(BuildContext context) async {
    var uid = FirebaseAuth.instance.currentUser?.uid;
    File file = File(selectedImage!.path);

    try {
      if (selectedImage != null && uid != null) {
        //Upload file
        final userFolderRef = storageRef.child('activity_logs/$uid/${selectedImage!.name}');
        var task = await userFolderRef.putFile(file);

        var downloadUrl = await userFolderRef.getDownloadURL();

        // Add Entry for File
        CollectionReference logs = firestore.collection("food_logs");
        DocumentReference doc = await logs.doc(uid).collection("activity").add({
          'type': 'image',
          'name': nameFieldController.text,
          'storagePath': task.ref.fullPath,
          'downaloadUrl': downloadUrl,
          'description': '',
          'log_date': DateTime.timestamp()
        });

        print(doc);

        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        //todo, show some message
      }
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      //todo show toast
    } on Exception catch (e) {
      debugPrint(e.toString());
      //todo show toast
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(children: [
        IconButton(
          icon: const Icon(Icons.camera),
          onPressed: () async {
            var image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
            if (image != null) {
              setState(() {
                selectedImage = image;
              });
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.photo),
          onPressed: () async {
            var image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
            if (image != null) {
              setState(() {
                selectedImage = image;
              });
            }
          },
        ),
      ]),
      Center(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
                width: 150,
                height: 150,
                child: Builder(builder: (context) {
                  if (selectedImage == null) {
                    return const Placeholder();
                  }

                  return Image.file(File(selectedImage!.path));
                }))),
        SizedBox(
          width: 250,
          height: 200,
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Add TextFormFields and ElevatedButton here.
                  TextFormField(
                    controller: nameFieldController,
                    decoration: const InputDecoration(labelText: 'Meal Name'),
                    validator: (value) {
                      return null;
                    },
                  ),
                  ElevatedButton(
                      onPressed: selectedImage != null
                          ? () {
                              if (_formKey.currentState!.validate()) {
                                saveImage(context);
                              }
                            }
                          : null,
                      child: const Text('Save Image'))
                ],
              )),
        )
      ]))
    ]);
  }
}
