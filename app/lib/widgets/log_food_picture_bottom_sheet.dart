import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:image_picker/image_picker.dart';

class LogFoodPictureBottomSheet extends StatefulWidget {
  const LogFoodPictureBottomSheet({super.key});

  @override
  State<LogFoodPictureBottomSheet> createState() => _LogFoodPictureBottomSheetState();
}

class _LogFoodPictureBottomSheetState extends State<LogFoodPictureBottomSheet> {

  final ImagePicker picker = ImagePicker();
  XFile? image;

  @override
  Widget build(BuildContext context) {
    return  Column(children:[
      Row(
        children: [
          OutlinedButton(onPressed: () async {
            image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              print(image!.path);
            }
          },
         child: const Text('pick image'),),
         Builder(
          builder: (context) {
            if( image == null ){
              //return const Text('');
            }

            return Text(image?.path ?? '');
          }
         )
        ],
      ),
      Row(
        children: [
          OutlinedButton(onPressed: () async {
            image = await picker.pickImage(source: ImageSource.camera);
            if (image != null) {
              print(image!.path);
            }
          },
            child: const Text('take picture'),),
          Builder(
              builder: (context) {
                if( image == null ){
                  //return const Text('');
                }

                return Text(image?.path ?? '');
              }
          )
        ],
      ),
      Row(
        children: [
          const OutlinedButton(onPressed: null,
            child: Text('scan barcode'),),
          Builder(
              builder: (context) {
                if( image == null ){
                  //return const Text('');
                }

                return Text(image?.path ?? '');
              }
          )
        ],
      )
    ]);
  }
}
