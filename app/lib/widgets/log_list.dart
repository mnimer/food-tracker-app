
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class LogList extends StatelessWidget {
  const LogList({
    super.key,
  });

  
  @override
  Widget build(BuildContext context) {

    CollectionReference logs = FirebaseFirestore.instance.collection('logs');


    return FutureBuilder<QuerySnapshot>(
        future: logs
            .where('user_id',
                isEqualTo: FirebaseAuth
                    .instance.currentUser?.uid)
            .get(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }
          if (!snapshot.hasData) {
            return const Text("No data available");
          }

          if (snapshot.connectionState ==
              ConnectionState.done) {
            for (var doc in snapshot.data!.docs) {
              const Text('item');
            }
          }

          return const Text("loading");
        },
      );
  }
}