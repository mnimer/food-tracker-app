import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:list_collections/widgets/log_food_picture_bottom_sheet.dart';
import 'package:list_collections/widgets/log_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Food Tracker"),
        actions: [
          OutlinedButton(
            child: const Text('Logout'),
            onPressed: () => {FirebaseAuth.instance.signOut()},
          )
        ],
      ),
      body: RefreshIndicator(
          onRefresh: refreshData,
          child: DefaultTabController(
              length: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                            child: SizedBox(
                          width: MediaQuery.of(context).size.width - 16,
                          height: 150,
                          child: const Center(child: OutlinedButton(onPressed: null, child: Text("Link Dexcom"))),
                        )),
                      ),
                    ),
                    Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(child: Text('Log')),
                            Tab(child: Text('Macros')),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 320,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TabBarView(children: [
                              LogList(),
                              Text('todo'),
                            ]),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 400,
              child: const Center(child: LogFoodPictureBottomSheet()),
            );
          },
        ),
        tooltip: 'Log Food',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
