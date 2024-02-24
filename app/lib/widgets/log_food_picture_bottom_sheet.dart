import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:image_picker/image_picker.dart';

class LogFoodPictureBottomSheet extends StatefulWidget {
  const LogFoodPictureBottomSheet({super.key});

  @override
  State<LogFoodPictureBottomSheet> createState() => _LogFoodPictureBottomSheetState();
}

class _LogFoodPictureBottomSheetState extends State<LogFoodPictureBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  void saveImage(BuildContext context) async {
    print('save image');

    if (context.mounted) {
      Navigator.pop(context);
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
        Container(
          width: 250,
          height: 200,
          child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Add TextFormFields and ElevatedButton here.
                  TextFormField(
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
                      child: const Text('Add Image'))
                ],
              )),
        )
      ]))
    ]);
  }
}
