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

  double? lat;
  double? long;

  getToken() async {
    String? Token =await _firebaseMessaging.getToken();
    print("----------------------");
    print(Token);
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
    if(permission == LocationPermission.whileInUse){
      print("whileInUse");
      Position position = await Geolocator.getCurrentPosition();
      print('------------------------------------');
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);

    }
    if(serviceEnabled == false){
      print('Error Location Service');
    }else{
      print("ok");
    }
  }

  MyrequestPremission() async
  {
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

      double? latitude = prefs.getDouble('latitude');
      double? longitude = prefs.getDouble('longitude');
      print("Stored Location: Lat = $latitude, Long = $longitude");
      lat = latitude;
      long = longitude;
  }


  @override
  void initState() {
    FirebaseMessaging.onMessage.listen((RemoteMessage massege){
      if(massege.notification != null){
        print("=====================");
        print(massege.notification!.title);
        print(massege.notification!.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content : Text("${massege.notification!.body}")));
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
        child: ListTile(
              title: const Text("Location"),
              subtitle: Text("Lat: $lat, Long: $long"),
        ),
      ),
    );
  }
}
