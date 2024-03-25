import 'package:cached_network_image/cached_network_image.dart';
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
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 75,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: widget.doc['downaloadUrl'],
                        progressIndicatorBuilder: (context, url, downloadProgress) =>
                            const SizedBox(width: 75, height: 75, child: Placeholder()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      )),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Column(
                        children: [
                          Text(
                            widget.doc['name'],
                            style: TextStyle(fontSize: 24),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width - 120,
                              child: Text(
                                widget.doc['description'],
                                style: TextStyle(fontSize: 16),
                              )),
                        ],
                      ),
                    ),
                  ),
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
