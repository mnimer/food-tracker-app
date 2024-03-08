import 'dart:async';
import 'dart:io' show HttpServer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;

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
          var tokenUrl = 'https://getdexcomtoken-xor7ewnbbq-uc.a.run.app/getDexcomToken?code=$code&state=$state';
          var response = await http.get(Uri.parse(tokenUrl));

          if (response.statusCode == 200) {
            var token = response.body;

            req.response.headers.add('Content-Type', 'text/html');
            req.response.write(html);
            req.response.close();
          } else {
            var body = response.body;
            var body2 = response.bodyBytes;
            print("${response.statusCode} | $body");
          }

          //Call to get Access_token
        }
      }
    });
  }

  void authenticateDexcom() async {
    var clientId = "6sURL7ulvbCpxbm834VOiihS3LZZS7AI";
    var uid = FirebaseAuth.instance.currentUser!.uid;
    //https://api.dexcom.com
    var redirectUrl = "http://127.0.0.1:43823";
    var url =
        "https://sandbox-api.dexcom.com/v2/oauth2/login?client_id=$clientId&redirect_uri=$redirectUrl&response_type=code&scope=offline_access&state=$uid";

    var callbackUrlScheme = 'foobar';

    try {
      final result = await FlutterWebAuth.authenticate(url: url, callbackUrlScheme: callbackUrlScheme);
      setState(() {
        print('Got result: $result');
      });
    } on PlatformException catch (e) {
      setState(() {
        print('Got error: $e');
      });
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
