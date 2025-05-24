import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Notifications setup
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'weather_channel',
    'Weather Service',
    description: 'This channel is used for weather monitoring service notifications.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  // Background service setup
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'weather_channel',
      initialNotificationTitle: 'Weather Monitoring',
      initialNotificationContent: 'Monitoring weather conditions',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Main background service handler
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Setup as a foreground service for Android
  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Make this a foreground service
    service.setAsForegroundService();
  }

  // Create notification plugin instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Run periodic check
  Timer.periodic(const Duration(hours: 1), (timer) async {
    // Check if service should still be running
    final prefs = await SharedPreferences.getInstance();
    final isMonitoring = prefs.getBool('isMonitoring') ?? false;

    if (!isMonitoring) {
      if (service is AndroidServiceInstance) {
        service.stopSelf();
      }
      timer.cancel();
      return;
    }

    try {
      // Make API call to get weather data
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=63cfd28ea6d2fa5383411aaaa87b9192&q=auto:ip'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final condition = data['current']['condition']['text'];
        final chanceOfRain = data['current']['precip_mm'];

        // Debugging: Log the weather data to check if it's correct
        print('Condition: $condition');
        print('Chance of Rain: $chanceOfRain');

        // Logic to determine bad weather
        if (condition.toLowerCase().contains("rain") || condition.toLowerCase().contains("storm") || chanceOfRain > 0.5) {
          await flutterLocalNotificationsPlugin.show(
            0,
            'Weather Alert',
            'Weather is bad, please remove clothes from the balcony.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'weather_alerts',
                'Weather Alerts',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }


        // Update running state periodically
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Weather Monitoring Active",
            content: "Last checked: ${DateTime.now().toString().split('.').first}",
          );
        }
      }
    } catch (e) {
      print('Weather service error: $e');
    }
  });

  // Do an immediate check on startup
  try {
    final response = await http.get(Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=63cfd28ea6d2fa5383411aaaa87b9192&q=auto:ip'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final condition = data['current']['condition']['text'];

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Weather Monitoring Active",
          content: "Current conditions: $condition",
        );
      }
    }
  } catch (e) {
    print('Initial weather check error: $e');
  }
}