import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DexcomChart extends StatefulWidget {
  const DexcomChart({required this.user, required this.date, super.key});

  final DateTime date;
  final Map<String, dynamic> user;

  @override
  State<DexcomChart> createState() => _DexcomChartState();
}

class _DexcomChartState extends State<DexcomChart> {
  List<Map<String, dynamic>> readings = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    var startDate = DateTime(widget.date.year, widget.date.month, widget.date.day).toLocal();
    var endDate = DateTime(widget.date.year, widget.date.month, widget.date.day + 1).toLocal();
    String uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      readings = [];
    });

    FirebaseFirestore.instance
        .collection("cgm_logs")
        .doc(uid)
        .collection("sensor_readings")
        .where("systemTime", isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
        .where("systemTime", isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
        .orderBy("systemTime", descending: true)
        .snapshots()
        .listen((event) {
      List<Map<String, dynamic>> data = [];
      for (var doc in event.docs) {
        Map<String, dynamic> d = doc.data();
        d['x'] = DateTime.fromMillisecondsSinceEpoch(d['systemTime']);
        data.add(d);
      }
      setState(() {
        readings = data;
      });
    });
  }

  Future<void> getLatestDexcomReadings() async {
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getDexcomReadings');
    await callable({"uid": widget.user['uid']});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
                child: Column(children: [
              isLoading
                  ? Container(width: 25, height: 25, child: const CircularProgressIndicator())
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        String? uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          setState(() {
                            isLoading = true;
                          });
                          HttpsCallable callable = FirebaseFunctions.instance.httpsCallable("getDexcomReadings");
                          await callable({"uid": uid});
                          //debugPrint(response.data);
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }),
              Container(
                  width: 400,
                  height: 175,
                  child: SfCartesianChart(
                    primaryYAxis: const NumericAxis(
                      anchorRangeToVisiblePoints: true,
                    ),
                    primaryXAxis: DateTimeAxis(
                      dateFormat: DateFormat.j(),
                      intervalType: DateTimeIntervalType.hours,
                      interval: 1,
                    ),
                    series: <LineSeries<Map<String, dynamic>, DateTime>>[
                      LineSeries<Map<String, dynamic>, DateTime>(
                        dataSource: readings,
                        xValueMapper: (Map<String, dynamic> reading, _) => reading['x'],
                        yValueMapper: (Map<String, dynamic> reading, _) => reading['value'],
                        color: Colors.blue,
                        width: 2,
                        markerSettings: const MarkerSettings(color: Colors.red),
                      ),
                    ],
                    zoomPanBehavior: ZoomPanBehavior(enablePanning: true, enablePinching: true, zoomMode: ZoomMode.x),
                  ))
            ]))));
  }
}
