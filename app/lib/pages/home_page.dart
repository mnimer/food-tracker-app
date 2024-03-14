import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/widgets/cgm_login.dart';
import 'package:food_tracker/widgets/dexcom_chart.dart';
import 'package:food_tracker/widgets/log_food_picture_bottom_sheet.dart';
import 'package:food_tracker/widgets/log_list.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  Future<void> refreshData() async {
    //await Future.delayed(const Duration(seconds: 1));
    setState(() {
      date = DateTime.now();
    });
  }

  DateTime date = DateTime.now();
  int duration = 1;

  @override
  void initState() {
    super.initState();

    //Listen to Authenticated User object
    User? authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      Stream<DocumentSnapshot<Map<String, dynamic>>> user =
          FirebaseFirestore.instance.collection("users").doc(authUser.uid).snapshots();

      user.listen((event) {
        setState(() {
          _isLoading = false;
          _user = event.data();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Food Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => {FirebaseAuth.instance.signOut()},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: refreshData,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          setState(() {
                            date = date.subtract(Duration(days: duration));
                          });
                        },
                      ),
                      Text(DateFormat.yMMMd().format(date)),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          if (date.difference(DateTime.now()).inDays < 0) {
                            setState(() {
                              date = date.add(Duration(days: duration));
                            });
                          }
                        },
                      ),
                    ]),
                    SizedBox(
                        width: MediaQuery.of(context).size.width - 16,
                        height: 250,
                        child: (!_user!.containsKey("dexcom") || _user!['dexcom']['login_required'])
                            ? const CgmLogin()
                            : SizedBox(height: 150, child: DexcomChart(user: _user!, date: date))),
                    DefaultTabController(
                        length: 2,
                        child: SizedBox(
                            width: MediaQuery.of(context).size.width - 16,
                            height: 430,
                            child: ListView(padding: const EdgeInsets.all(8), children: <Widget>[
                              const TabBar(
                                tabs: [
                                  Tab(child: Text('Log')),
                                  Tab(child: Text('Macros')),
                                ],
                              ),
                              Container(
                                height: 500,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TabBarView(children: [
                                    LogList(days: 1, date: date),
                                    const Text('todo'),
                                  ]),
                                ),
                              )
                            ]))),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return SizedBox(
              height: 400,
              width: MediaQuery.of(context).size.width,
              child: Center(child: LogFoodPictureBottomSheet(date: date)),
            );
          },
        ),
        tooltip: 'Log Food',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
