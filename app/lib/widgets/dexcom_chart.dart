import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class DexcomChart extends StatefulWidget {
  const DexcomChart({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  State<DexcomChart> createState() => _DexcomChartState();
}

class _DexcomChartState extends State<DexcomChart> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> getLatestDexcomReadings() async {
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getDexcomReadings');
    final results = await callable({"uid": widget.user['uid']});

    List readings = results.data;
    print(readings);
  }

  @override
  Widget build(BuildContext context) {
    return const Text("chart here");
  }
}
