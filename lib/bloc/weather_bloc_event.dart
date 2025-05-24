part of 'weather_bloc_bloc.dart';

sealed class WeatherBlocEvent extends Equatable {
  const WeatherBlocEvent();

  @override
  List<Object> get props => [];
}

class WeatherFetchEvent extends WeatherBlocEvent{
  final Position pos;

  WeatherFetchEvent({required this.pos});

  @override
  List<Object> get props => [pos];

}

class WeatherFetchByCityEvent extends WeatherBlocEvent{
  final String city;
  WeatherFetchByCityEvent(this.city);
}

class FetchTopCitiesWeather extends WeatherBlocEvent{}