import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogList extends StatelessWidget {
  const LogList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var uid = FirebaseAuth.instance.currentUser?.uid;
    CollectionReference logs = FirebaseFirestore.instance.collection('food_logs').doc(uid).collection("activity");

    return FutureBuilder<QuerySnapshot>(
        future: logs.get(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            if (!snapshot.hasData) {
              return const Text("No data available");
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.size,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return ListTile(
                    title: Text(doc['name'] ?? ''),
                    subtitle: Text(doc['description'] ?? ''),
                    leading: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                        maxWidth: 64,
                        maxHeight: 64,
                      ),
                      child: Image.network(doc['downaloadUrl'], fit: BoxFit.cover),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                  );
                },
              );
            }
          }

          return Container();
        });
  }
}
