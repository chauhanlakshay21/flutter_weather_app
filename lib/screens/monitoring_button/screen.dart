import 'package:flutter/material.dart';
import 'package:weather/weather.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:tmep/bloc/weather_bloc_bloc.dart';

import 'only_monitor_button.dart';

class ClothesGuardScreen extends StatefulWidget {
  const ClothesGuardScreen({Key? key}) : super(key: key);

  @override
  State<ClothesGuardScreen> createState() => _ClothesGuardScreenState();
}

class _ClothesGuardScreenState extends State<ClothesGuardScreen> with SingleTickerProviderStateMixin {
  bool isMonitoring = true;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Check if weather data is already loaded, otherwise fetch it
    final weatherState = context.read<WeatherBlocBloc>().state;
    if (weatherState is! WeatherBlocSuccess) {
      _fetchWeatherData();
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      Position pos = await _determinePosition();
      context.read<WeatherBlocBloc>().add(WeatherFetchEvent(pos: pos));
    } catch (e) {
      // Handle location error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  Future<void> _refreshWeather() async {
    try {
      Position pos = await _determinePosition();
      context.read<WeatherBlocBloc>().add(WeatherFetchEvent(pos: pos));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing weather: $e')),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to determine if weather is safe for clothes
  String getWeatherSafetyStatus(Weather weather) {
    // Check for rain
    if (weather.weatherMain?.toLowerCase().contains('rain') == true ||
        weather.weatherMain?.toLowerCase().contains('shower') == true ||
        weather.weatherMain?.toLowerCase().contains('drizzle') == true) {
      return 'Not safe for clothes';
    }

    // Check for high wind (above 20 km/h might be risky)
    if (weather.windSpeed != null && weather.windSpeed! > 5.5) { // ~20 km/h
      return 'Caution: windy condition';
    }

    return 'Safe for clothes';
  }

  // Helper to determine safety color
  Color getWeatherSafetyColor(String status) {
    if (status.contains('Not safe')) {
      return const Color(0xFFFFDAD6); // Light red
    } else if (status.contains('Caution')) {
      return const Color(0xFFFFECB3); // Light amber
    } else {
      return const Color(0xFFB3E0D1); // Light green
    }
  }

  // Helper to determine safety text color
  Color getWeatherSafetyTextColor(String status) {
    if (status.contains('Not safe')) {
      return const Color(0xFFB71C1C); // Dark red
    } else if (status.contains('Caution')) {
      return const Color(0xFFAB7D36); // Dark amber
    } else {
      return const Color(0xFF146B47); // Dark green
    }
  }

  // Get weather warning text
  String getWeatherWarning(Weather weather) {
    if (weather.rainLastHour != null && weather.rainLastHour! > 0) {
      return 'Rain detected in the last hour';
    }

    if (weather.weatherDescription?.toLowerCase().contains('rain') == true) {
      final num probability = (weather.cloudiness ?? 0).clamp(20, 90);
      return 'Rain chance: $probability% in next few hours';
    }

    if (weather.cloudiness != null && weather.cloudiness! > 60) {
      return 'Cloudy weather: ${weather.cloudiness}% cloud cover';
    }

    return 'Weather looks stable for the next few hours';
  }

  // Determine if it's currently night time based on sunrise/sunset
  bool isNightTime(Weather weather) {
    final DateTime now = DateTime.now();
    final DateTime? sunrise = weather.sunrise;
    final DateTime? sunset = weather.sunset;

    if (sunrise == null || sunset == null) {
      // Fallback to using the hour if sunrise/sunset data isn't available
      final int currentHour = now.hour;
      return currentHour < 6 || currentHour >= 19; // Consider night between 7pm and 6am
    }

    return now.isBefore(sunrise) || now.isAfter(sunset);
  }

  // Get background gradient based on day/night
  List<Color> getBackgroundGradient(bool isNight) {
    if (isNight) {
      // Night time gradient (dark blue to midnight blue)
      return [
        const Color(0xFF0F2043), // Dark blue
        const Color(0xFF1E3A5F), // Midnight blue
      ];
    } else {
      // Day time gradient (light blue)
      return [
        const Color(0xFF4285F4), // Light blue
        const Color(0xFFCFE2FF), // Very light blue
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WeatherBlocBloc, WeatherBlocState>(
        builder: (context, state) {
          // Default to day time gradient
          List<Color> backgroundGradient = [
            const Color(0xFF4285F4),
            const Color(0xFFCFE2FF)
          ];

          // Update gradient if we have weather data
          if (state is WeatherBlocSuccess) {
            backgroundGradient = getBackgroundGradient(isNightTime(state.weather));
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: backgroundGradient,
                stops: const [0.0, 0.3],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // AppBar with back button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'ClothesGuard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildContent(state),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(WeatherBlocState state) {
    if (state is WeatherBlocLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    } else if (state is WeatherBlocSuccess) {
      final Weather weather = state.weather;
      final String safetyStatus = getWeatherSafetyStatus(weather);
      final bool isNight = isNightTime(weather);

      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Weather Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isNight ? Icons.nightlight_round : Icons.wb_sunny,
                          color: isNight ? Colors.indigo[400] : Colors.amber[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Weather',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4D6278),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${weather.areaName})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF607D8B),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _refreshWeather,
                      child: Icon(
                        _getWeatherIcon(weather.weatherConditionCode ?? 800),
                        color: Colors.blue[400],
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature?.celsius?.round()}°C',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          weather.weatherMain ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF607D8B),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getWeatherSafetyColor(safetyStatus),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        safetyStatus,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: getWeatherSafetyTextColor(safetyStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFE9AF56),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        getWeatherWarning(weather),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFAB7D36),
                        ),
                      ),
                    ),
                  ],
                ),
                if (weather.sunrise != null && weather.sunset != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.blueGrey[400],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sunrise: ${DateFormat('h:mm a').format(weather.sunrise!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Sunset: ${DateFormat('h:mm a').format(weather.sunset!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Weather details
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDetailItem(
                        Icons.water_drop,
                        'Humidity',
                        '${weather.humidity?.round() ?? "N/A"}%'
                    ),
                    _buildDetailItem(
                        Icons.air,
                        'Wind',
                        '${weather.windSpeed?.toStringAsFixed(1) ?? "N/A"} m/s'
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDetailItem(
                        Icons.speed,
                        'Pressure',
                        '${weather.pressure ?? "N/A"} hPa'
                    ),
                    _buildDetailItem(
                        Icons.thermostat,
                        'Feels Like',
                        '${weather.tempFeelsLike?.celsius?.round() ?? "N/A"}°C'
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Monitoring Button
           MonitorButton(isNight: isNight),
          // Alert Settings
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () {
                // Navigate to alert settings
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Alert Settings',
                style: TextStyle(
                  color: isNight ? Colors.indigo[400] : const Color(0xFF4285F4),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (state is WeatherBlocFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Error loading weather data",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchWeatherData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    } else {
      // Initial state or other states
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4285F4),
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF607D8B),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code >= 200 && code < 300) {
      return Icons.thunderstorm;
    } else if (code >= 300 && code < 400) {
      return Icons.grain;
    } else if (code >= 500 && code < 600) {
      return Icons.umbrella;
    } else if (code >= 600 && code < 700) {
      return Icons.ac_unit;
    } else if (code >= 700 && code < 800) {
      return Icons.cloud;
    } else if (code == 800) {
      return Icons.wb_sunny;
    } else {
      return Icons.cloud;
    }
  }
}



/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
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