import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/pages/meal_details_page.dart';

class LogList extends StatelessWidget {
  const LogList({super.key, this.days = 1, required this.date});

  final DateTime date;
  final int days;

  @override
  Widget build(BuildContext context) {
    var uid = FirebaseAuth.instance.currentUser?.uid;
    var end = date.add(Duration(days: days));
    var startDate = DateTime(date.year, date.month, date.day);
    var endDate = DateTime(end.year, end.month, end.day);
    var logs = FirebaseFirestore.instance
        .collection('food_logs')
        .doc(uid)
        .collection("activity")
        .where("log_date", isGreaterThan: Timestamp.fromDate(startDate))
        .where("log_date", isLessThan: Timestamp.fromDate(endDate))
        .orderBy("log_date", descending: true);

    return StreamBuilder<QuerySnapshot>(
        stream: logs.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // Display a loading indicator while waiting for data
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString()); // Handle errors
          } else if (!snapshot.hasData) {
            return const Text("No Data"); // Handle the case when there's no data
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.size,
              itemBuilder: (context, index) {
                dynamic doc = snapshot.data!.docs[index].data();
                var nutrients = doc['nutrients'] ?? [];
                var carbs = nutrients.firstWhere((e) => e['name'] == "Carbohydrates", orElse: () => '');
                var protein = nutrients.firstWhere((e) => e['name'] == "Protein", orElse: () => '');
                var calories = nutrients.firstWhere((e) => e['name'] == "Calories", orElse: () => '');
                return ListTile(
                  title: Text(doc['name'] ?? ''),
                  subtitle: (doc['status'] == "processing")
                      ? Container(width: 44, height: 44, child: const CircularProgressIndicator())
                      : Column(children: [
                          Text(
                            doc['description'] ?? '',
                            textScaler: const TextScaler.linear(.9),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                            softWrap: true,
                          ),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                            (carbs.isNotEmpty)
                                ? SizedBox(width: 44, height: 44, child: NutrientBox(label: "Carbs", nutrient: carbs))
                                : Container(),
                            (protein.isNotEmpty)
                                ? SizedBox(
                                    width: 44, height: 44, child: NutrientBox(label: "Protein", nutrient: protein))
                                : Container(),
                            (calories.isNotEmpty)
                                ? SizedBox(
                                    width: 44, height: 44, child: NutrientBox(label: "Calories", nutrient: calories))
                                : Container(),
                          ])
                        ]),
                  leading: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                      maxWidth: 64,
                      maxHeight: 64,
                    ),
                    child: SizedBox(width: 75, child: Image.network(doc['downaloadUrl'], fit: BoxFit.cover)),
                  ),
                  trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MealDetailsPage(doc: doc)),
                        );
                      }),
                );
              },
            );
          }

          return Container();
        });
  }
}

class NutrientBox extends StatelessWidget {
  const NutrientBox({
    super.key,
    required this.label,
    required this.nutrient,
  });

  final label;
  final nutrient;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white30,
          border: Border.all(width: 1, color: Colors.white10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
            padding: const EdgeInsets.all(2),
            child:
                Column(children: [Text(label, textScaler: const TextScaler.linear(.7)), Text(nutrient['quantity'])])));
  }
}
