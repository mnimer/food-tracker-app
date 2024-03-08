import 'package:flutter/material.dart';

class MealDetailsPage extends StatefulWidget {
  const MealDetailsPage({super.key, required this.doc});

  final Map doc;

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  @override
  Widget build(BuildContext context) {
    var nutrients = widget.doc['nutrients'] ?? [];
    var ingredients = widget.doc['ingredients'] ?? [];

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Meal Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text(
              widget.doc['name'],
              textScaler: const TextScaler.linear(2),
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 75, child: Image.network(widget.doc['downaloadUrl'], fit: BoxFit.cover)),
                  SizedBox(width: MediaQuery.of(context).size.width - 120, child: Text(widget.doc['description'])),
                ]),
            Container(height: 24),
            const Text(
              "Ingredients",
              textScaler: TextScaler.linear(1.5),
            ),
            Table(
              children: [
                const TableRow(
                  children: [
                    Text('Name'),
                    Text('Quantity'),
                  ],
                ),
                for (var ingredient in ingredients)
                  TableRow(
                    children: [
                      Text(ingredient['name']),
                      Text(ingredient['quantity']),
                    ],
                  ),
              ],
            ),
            Container(height: 24),
            const Text("Nutrients", textScaler: TextScaler.linear(1.5)),
            Table(
              children: [
                const TableRow(
                  children: [
                    Text('Name'),
                    Text('Quantity'),
                  ],
                ),
                for (var nutrient in nutrients)
                  TableRow(
                    children: [
                      Text(nutrient['name']),
                      Text(nutrient['quantity']),
                    ],
                  ),
              ],
            ),
          ]),
        )));
  }
}
