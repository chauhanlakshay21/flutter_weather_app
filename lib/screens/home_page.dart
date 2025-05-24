import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:tmep/bloc/weather_bloc_bloc.dart';
import 'package:tmep/screens/top_cities_weather.dart';
import 'package:tmep/ui/helper.dart';
import 'package:weather/weather.dart';

import 'monitoring_button/screen.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String getGreeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String getWeatherImage(int code) {
    if (code >= 200 && code < 300) {
      return "assets/png/1.png"; // Thunderstorm
    } else if (code >= 300 && code < 400) {
      return "assets/png/2.png"; // Drizzle
    } else if (code >= 500 && code < 600) {
      return "assets/png/3.png"; // Rain
    } else if (code >= 600 && code < 700) {
      return "assets/png/4.png"; // Snow
    } else if (code >= 700 && code < 800) {
      return "assets/png/5.png"; // Atmosphere (mist, smoke, etc.)
    } else if (code == 800) {
      return "assets/png/6.png"; // Clear
    } else if (code > 800 && code <= 804) {
      return "assets/png/7.png"; // Clouds
    } else {
      return "assets/png/1.png"; // Default fallback
    }
  }


  Future<void> _searchByCity(String city) async {
    context.read<WeatherBlocBloc>().add(WeatherFetchByCityEvent(city));
  }

  Future<void> _refresh() async {
    Position pos = await _determinePosition();
    context.read<WeatherBlocBloc>().add(WeatherFetchEvent(pos: pos));
  }

  void _enterCity(BuildContext context) {
    final TextEditingController _cityCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // translucent background
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Search by City",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Raleway",
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _cityCtrl,
                      style: TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: "Enter City Name",
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("Cancel",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _searchByCity(_cityCtrl.text.toString());
                          },
                          child: Text("OK",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "Raleway")),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   systemOverlayStyle:
      //       const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
      // ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.05,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              BlurryBackground(),
              BlocBuilder<WeatherBlocBloc, WeatherBlocState>(
                builder: (context, state) {
                  if (state is WeatherBlocLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is WeatherBlocInitial) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is WeatherBlocSuccess) {
                    final Weather weather = state.weather;
                    return SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${weather.areaName}',
                                style: TextStyle(
                                  fontFamily: "Raleway",
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              IconButton(
                                  onPressed: () => _enterCity(context),
                                  icon: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                          Text(
                            getGreeting(weather.date!.hour),
                            style: TextStyle(
                                fontFamily: "Raleway",
                                color: Colors.white,
                                fontSize: size.width * 0.06,
                                fontWeight: FontWeight.bold),
                          ),
                          Center(
                            child: Image.asset(
                                width: size.width * 0.6,
                                height: size.width * 0.6,
                                getWeatherImage(weather.weatherConditionCode!)),
                          ),
                          Center(
                            child: Text(
                              '${weather.temperature!.celsius!.round()}°C',
                              style: TextStyle(
                                  fontFamily: "Raleway",
                                  color: Colors.white,
                                  fontSize: size.width * 0.11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Center(
                            child: Text(
                              weather.weatherMain!,
                              style: TextStyle(
                                  fontFamily: "Raleway",
                                  color: Colors.white,
                                  fontSize: size.width * 0.06,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${DateFormat('EEEE d . h:mm a').format(weather.date!)}',
                              style: TextStyle(
                                  fontFamily: "Raleway",
                                  color: Colors.white38,
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          SizedBox(height: size.height * 0.018),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  Flexible(
                                    child: SmallCard(
                                      imgPath: 'assets/png/11.png',
                                      top: 'Sunrise',
                                      bottom: DateFormat('h:mm a')
                                          .format(weather.sunrise!),
                                    ),
                                  ),
                                  Flexible(
                                    child: SmallCard(
                                      imgPath: 'assets/png/12.png',
                                      top: 'Sunset',
                                      bottom: DateFormat('h:mm a')
                                          .format(weather.sunset!),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: size.height * 0.006),
                                child: Divider(color: Colors.grey[800]),
                              ),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                                children: [
                                  Flexible(
                                    child: SmallCard(
                                      imgPath: 'assets/png/13.png',
                                      top: 'Temp Max',
                                      bottom:
                                      '${weather.tempMax!.celsius!.round()}°C',
                                    ),
                                  ),
                                  Flexible(
                                    child: SmallCard(
                                      imgPath: 'assets/png/14.png',
                                      top: 'Temp Min',
                                      bottom:
                                      '${weather.tempMin!.celsius!.round()}°C',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 40,),
                          Column(
                            children: [
                              Center(
                                child: ElevatedButton(

                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ClothesGuardScreen()),
                                      );
                                    }, child: Text('Start monitoring')),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "An error occurred.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * 0.046,
                            ),
                          ),
                          SizedBox(height: size.height * 0.012),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              shadowColor: Colors.white38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.white10),
                              ),
                            ),
                            onPressed: () {
                              _refresh();
                            },
                            icon: Icon(Icons.refresh),
                            label: Text("Retry"),
                          )
                        ],
                      ),
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<WeatherBlocBloc, WeatherBlocState>(
        builder: (context, state) {
          if(state is WeatherBlocSuccess){
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<WeatherBlocBloc>(),
                      child: ForeCast(),
                    ),
                  ),
                );
              },
              child: SvgPicture.asset("assets/svg/Map.svg"),
            );
          }else{
            return SizedBox();
          }

        },
      ),
    );
  }
}



/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the Future will return an error.
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