import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/weather_model.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const BASE_URL = "http://api.openweathermap.org/data/2.5/weather";
  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    final response = await http
        .get(Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load weather data");
    }
  }

  Future<String> getCurrentCity() async {
    try {
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception(
              "Location services are disabled. Please enable location services in your device settings.");
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
              "Location permission is required to get weather for your current location.");
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? city = placemarks.first.locality;
      if (city == null || city.isEmpty) {
        city = placemarks.first.subAdministrativeArea;
      }
      if (city == null || city.isEmpty) {
        throw Exception("Could not determine your city location.");
      }

      return city;
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception(
            "Location request timed out. Please check your GPS signal and try again.");
      }

      if (kIsWeb && e.toString().contains('NotAllowed')) {
        throw Exception(
            "Please allow location access in your browser to get weather information.");
      }

      if (e is Exception) {
        rethrow;
      }
      throw Exception("Failed to get current location: ${e.toString()}");
    }
  }
}
