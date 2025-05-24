import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tmep/api_key.dart';
import 'package:weather/weather.dart';

part 'weather_bloc_event.dart';
part 'weather_bloc_state.dart';

class WeatherBlocBloc extends Bloc<WeatherBlocEvent, WeatherBlocState> {
  WeatherBlocBloc() : super(WeatherBlocInitial()) {
    on<WeatherFetchEvent>((event, emit) async{
      emit(WeatherBlocLoading());
      try{
        double lat = event.pos.latitude;
        double lon = event.pos.longitude;
        String key = api_key;
        WeatherFactory wf = WeatherFactory(key);

        Weather weather = await wf.currentWeatherByLocation(lat, lon);
        
        print("weather");
        print(weather);
        print("Position");
        print(event.pos);

        emit(WeatherBlocSuccess(weather));
      }catch(e){
        emit(WeatherBlocFailure());
      }
    });
    on<WeatherFetchByCityEvent>((event, emit) async{
      emit(WeatherBlocLoading());
      try{
        String key = api_key;
        WeatherFactory wf = WeatherFactory(key);

        Weather weather = await wf.currentWeatherByCityName(event.city);
        // print("weather");
        // print(weather);
        // print("Position");
        // print(event.pos);

        emit(WeatherBlocSuccess(weather));
      }catch(e){
        emit(WeatherBlocFailure());
      }
    });
    on<FetchTopCitiesWeather>((event, emit) async{
      emit(WeatherBlocLoading());
      try{
        String key = api_key;
        WeatherFactory wf = WeatherFactory(key);
        List<Weather> w = [];

        List<String> cities = ['Mumbai','Delhi','Bengaluru','Chennai','Kolkata','Hyderabad','Ahmedabad','Pune','Jaipur','Varanasi',];
        for(String city in cities){
          Weather weather = await wf.currentWeatherByCityName(city);
          w.add(weather);
        }
        // print("foreCast");
        // print(w[0]);
        // print("Position");
        // print(event.pos);

        emit(TopCitiesWetherSuccess(weathers: w));
      }catch(e){
        emit(WeatherBlocFailure());
      }
    });
  }
}
