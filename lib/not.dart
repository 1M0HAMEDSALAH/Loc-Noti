import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAppnoti extends StatefulWidget {
  @override
  _MyAppnotiState createState() => _MyAppnotiState();
}

class _MyAppnotiState extends State<MyAppnoti> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  List<Map<String, double>> locationList = [];

  getToken() async {
    String? token = await _firebaseMessaging.getToken();
    print("----------------------");
    print(token);
  }

  GetTheCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.whileInUse) {
      print("whileInUse");
      Position position = await Geolocator.getCurrentPosition();
      print('------------------------------------');
      SharedPreferences prefs = await SharedPreferences.getInstance();


      String? locationJson = prefs.getString('locationListMap');
      List<Map<String, double>> storedLocations = [];

      if (locationJson != null) {
        storedLocations = List<Map<String, double>>.from(
            jsonDecode(locationJson).map((item) => Map<String, double>.from(item))
        );
      }

      storedLocations.add({
        'latitude': position.latitude,
        'longitude': position.longitude
      });


      String updatedLocationJson = jsonEncode(storedLocations);
      await prefs.setString('locationListMap', updatedLocationJson);

      print("Location stored as List of Maps: $updatedLocationJson");
      loadLocations();
    }

    if (!serviceEnabled) {
      print('Error Location Service');
    } else {
      print("Location Service is enabled");
    }
  }

  MyrequestPremission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  loadLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? locationJson = prefs.getString('locationListMap');

    if (locationJson != null) {
      List<Map<String, double>> locationListFromPrefs = List<Map<String, double>>.from(
          jsonDecode(locationJson).map((item) => Map<String, double>.from(item))
      );
      setState(() {
        locationList = locationListFromPrefs;
      });
    } else {
      print("No location stored.");
    }
  }

  @override
  void initState() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print("=====================");
        print(message.notification!.title);
        print(message.notification!.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${message.notification!.body}")));
        GetTheCurrentLocation();
      }
    });
    getToken();
    loadLocations();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification & Location"),
      ),
      body: Center(
        child: locationList.isEmpty
            ? const CircularProgressIndicator()
            : ListView.builder(
          itemCount: locationList.length,
          itemBuilder: (context, index) {
            var location = locationList[index];
            double latitude = location['latitude']!;
            double longitude = location['longitude']!;
            return ListTile(
              title: const Text("Location"),
              subtitle: Text("Lat: $latitude, Long: $longitude"),
            );
          },
        ),
      ),
    );
  }
}
