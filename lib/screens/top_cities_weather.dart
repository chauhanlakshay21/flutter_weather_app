import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tmep/bloc/weather_bloc_bloc.dart';
import 'package:tmep/ui/helper.dart';
import 'package:weather/weather.dart';

class ForeCast extends StatefulWidget {
  @override
  State<ForeCast> createState() => _ForeCastState();
}

class _ForeCastState extends State<ForeCast> {
  void initState() {
    super.initState();
    context
        .read<WeatherBlocBloc>()
        .add(FetchTopCitiesWeather());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Top Cities Weather", style: TextStyle(color:Colors.white, fontFamily: "Raleway"),),
        centerTitle: true,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_ios, color: Colors.white,)),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
          vertical: size.height * 0.02,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              BlurryBackground(),
              BlocBuilder<WeatherBlocBloc, WeatherBlocState>(
                builder: (context, state){
                  if(state is WeatherBlocLoading){
                    return Center(child: CircularProgressIndicator(),);
                  }
                  else if(state is TopCitiesWetherSuccess){
                    return ListView.builder(
                      itemCount: state.weathers.length,
                      itemBuilder: (context, index){
                        return WeatherCardFancy(weather: state.weathers[index],);
                      }
                    );
                  }
                  else{
                    return Center(child: CircularProgressIndicator(),);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}


class WeatherCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from bottom-right with rounded corner
    path.moveTo(size.width, size.height - 30);
    path.quadraticBezierTo(size.width, size.height, size.width - 30, size.height);

    // Bottom-left corner
    path.lineTo(30, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 30);

    // Top-left corner
    path.lineTo(0, 30);
    path.quadraticBezierTo(0, 0, 30, 0);

    // Top-right slanted downward
    path.lineTo(size.width - 80, size.height * 0.15);
    path.quadraticBezierTo(size.width, size.height * 0.2, size.width, size.height * 0.3);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class WeatherCardFancy extends StatelessWidget {
  final Weather weather;

  const WeatherCardFancy({super.key, required this.weather});

  String getWeatherImage(int code) {
    switch (code) {
      case >= 200 && < 300:
        return "assets/png/1.png";
      case >= 300 && < 400:
        return "assets/png/2.png";
      case >= 500 && < 600:
        return "assets/png/3.png";
      case >= 600 && < 700:
        return "assets/png/4.png";
      case >= 700 && < 800:
        return "assets/png/5.png";
      case == 800:
        return 'assets/png/6.png';
      case > 800 && <= 804:
        return "assets/png/7.png";
      default:
        return "assets/png/1.png";
    }
  }

@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20.0),
    child: SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Clipped glass card
          ClipPath(
            clipper: WeatherCardClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    colors: [
                        Colors.white.withOpacity(0.50), // More opaque
                        Colors.white.withOpacity(0.505) // More transparent
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    // Temperature & details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${weather.temperature!.celsius!.round()}°',
                            style: const TextStyle(
                              fontFamily: "Raleway",
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'H:${weather.tempMax!.celsius!.round()}°  L:${weather.tempMin!.celsius!.round()}°',
                            style: const TextStyle(
                              fontFamily: "Raleway",
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${weather.areaName}, ${weather.country}',
                            style: const TextStyle(
                              fontFamily: "Raleway",
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Text(
                          weather.weatherDescription ?? '',
                          style: const TextStyle(
                            fontFamily: "Raleway",
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Image
          Positioned(
            right: 0,
            top: -20,
            child: Image.asset(
              getWeatherImage(weather.weatherConditionCode!),
              height: 150,
            ),
          ),
        ],
      ),
    ),
  );
}

}

