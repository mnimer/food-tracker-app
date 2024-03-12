import 'dart:async';
import 'dart:io' show HttpServer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

const html = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Access Granted</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script>
  setTimeout("window.close()", 100);
</script>
</head>
<body>
  <main>
    <div id="text">You are logged in, please close this window</div>
  </main>
</body>
</html>
""";
const errorHtml = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Access Granted</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script>
  setTimeout("window.close()", 100);
</script>
</head>
<body>
  <main>
    <div id="text">Error with Authentication, close browser and try again. If problem persist contact support.</div>
  </main>
</body>
</html>
""";

class CgmLogin extends StatefulWidget {
  const CgmLogin({super.key});
  @override
  State<CgmLogin> createState() => _CgmLoginState();
}

class _CgmLoginState extends State<CgmLogin> {
  @override
  void initState() {
    super.initState();
    startServer();
  }

  Future<void> startServer() async {
    final server = await HttpServer.bind('127.0.0.1', 43823, shared: true);

    server.listen((req) async {
      var code = req.uri.queryParameters['code'];
      var state = req.uri.queryParameters['state'];
      var error = req.uri.queryParameters['error'];

      if (error != null || code != null) {
        if (error != null) {
          //todo show error html
        } else {
          try {
            //Call to get Access_token.  Cloud Function will update user with OAUTH details
            HttpsCallable callable = FirebaseFunctions.instance.httpsCallable("getDexcomToken");
            final response = await callable({"code": code, "state": state});

            //var tokenUrl = 'https://getdexcomtoken-xor7ewnbbq-uc.a.run.app/getDexcomToken?code=$code&state=$state';
            //var response = await http.get(Uri.parse(tokenUrl));

            var token = await response.data;
            debugPrint(token);

            req.response.headers.add('Content-Type', 'text/html');
            req.response.write(html);
            req.response.close();
          } catch (err) {
            debugPrint("$err");
            req.response.headers.add('Content-Type', 'text/html');
            req.response.write(errorHtml);
            req.response.close();
          }
        }
      }
    });
  }

  void authenticateDexcom() async {
    var clientId = "6sURL7ulvbCpxbm834VOiihS3LZZS7AI";
    var uid = FirebaseAuth.instance.currentUser!.uid;
    //https://api.dexcom.com
    var redirectUrl = "http://127.0.0.1:43823";
    var host = "https://api.dexcom.com";
    host = "https://sandbox-api.dexcom.com";
    var url =
        "$host/v2/oauth2/login?client_id=$clientId&redirect_uri=$redirectUrl&response_type=code&scope=offline_access&state=$uid";

    var callbackUrlScheme = 'foobar';

    try {
      final result = await FlutterWebAuth.authenticate(url: url, callbackUrlScheme: callbackUrlScheme);
      //debugPrint('Got result: $result');
    } on PlatformException catch (e) {
      debugPrint('Got error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
            child: SizedBox(
          width: MediaQuery.of(context).size.width - 16,
          height: 150,
          child: Center(child: OutlinedButton(onPressed: () => authenticateDexcom(), child: const Text("Link Dexcom"))),
        )),
      ),
    );
  }
}
