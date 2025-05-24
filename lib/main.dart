import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tmep/bloc/weather_bloc_bloc.dart';
import 'package:tmep/screens/home_page.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'bloc/background_tasks.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await initializeService();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);


  runApp(BlocProvider(
    create: (_) => WeatherBlocBloc(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
          future: determinePosition(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return BlocProvider(
                create: (context) => WeatherBlocBloc()
                  ..add(WeatherFetchEvent(pos: snapshot.data as Position)),
                child: HomePage(),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text("Failed to get location: ${snapshot.error}"),
                ),
              );
            } else {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            }
          }),
    );
  }
}

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the *`Future`* will return an error.
Future<Position> determinePosition() async {
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
  Position curpos = await Geolocator.getCurrentPosition();
  print("-----------------------------------------------");
  print("-----------------------------------------------");
  print("-----------------------------------------------");
  print("-----------------------------------------------");
  print(curpos.latitude);
  print(curpos.longitude);
  print("-----------------------------------------------");
  print("-----------------------------------------------");
  print("-----------------------------------------------");
  print("-----------------------------------------------");

  return curpos;




}

