import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      body: DefaultTabController(
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
                      child: const Center(
                          child: OutlinedButton(
                              onPressed: null, child: Text("Link Dexcom"))),
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
                      height: MediaQuery.of(context).size.height - 280,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TabBarView(children: [
                          Text('Log'),
                          const Text('todo'),
                        ]),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: (() => {}),
        tooltip: 'Log Food',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
