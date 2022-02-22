import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:dart_ipify/dart_ipify.dart';

void main() {
  runApp(MyApp());
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future<List> fetchAlbum() async {
  final response =
      await http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos'));
  final response2 =
      await http.get(Uri.parse('http://localhost:5000/api/locations'));
  print(response2.body);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load album');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sky Mavis',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Sky Mavis'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _counter = '';
  String ipv4 = '';
  String mygeo = '';
  String latlong = '';
  late Future<List> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  void _incrementCounter() async {
    final ip = await Ipify.ipv4();
    final geo = await Ipify.geo('at_q45RwWwG71w0CvON3ioUJuPwYgm75');
    final coords = await _determinePosition();
    setState(() {
      _counter = '$ipv4';
      ipv4 = '$ip';
      mygeo = '$geo';
      latlong = '$coords';
    });
  }

  getWidget() {
    if (_counter.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(80),
        child: Column(
          children: [
            Text('$ipv4',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 30)),
            Text('$mygeo',
                style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            Text('$latlong',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 30)),
          ],
        ),
      );
    }
    return Text(
      'Please click the + icon and accept permissions =)',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sky Mavis Exam:'),
      ),
      body: FutureBuilder<List>(
        future: futureAlbum,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    children: <Widget>[
                      getWidget(),
                    ],
                  )),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const CircularProgressIndicator();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
