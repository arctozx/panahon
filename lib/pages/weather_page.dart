import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:panahon/models/weather_model.dart';
import 'package:panahon/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService('7595f4f472ec61668cc07b0428eea192');
  Weather? _weather;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      await _fetchWeather();
    } catch (e) {
      if (e.toString().toLowerCase().contains('location')) {
        _showLocationDialog();
      }
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app needs access to location to show weather information.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            if (kIsWeb) ...[
              Text(
                'For web browsers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '1. Look for the location icon in your browser\'s address bar'),
              Text('2. Click it and choose "Allow"'),
              Text('3. Refresh the page if needed'),
            ] else ...[
              Text(
                'Please ensure:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. Location permissions are granted in device settings'),
              Text('2. Location/GPS is enabled on your device'),
            ],
          ],
        ),
        actions: [
          if (!kIsWeb) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openLocationSettings();
              },
              child: const Text('Open Location Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: const Text('Open App Settings'),
            ),
          ],
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkLocationPermission();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchWeather() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String cityName = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(cityName);

      if (mounted) {
        setState(() {
          _weather = weather;
          _errorMessage = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });

        if (e.toString().toLowerCase().contains('location')) {
          _showLocationDialog();
        }
      }
    }
  }

  String getWeatherConditionAsset(String? mainCondition) {
    if (mainCondition == null) {
      return "assets/sunny.json";
    }

    switch (mainCondition.toLowerCase()) {
      case "clouds":
        return "assets/cloudy.json";
      case "rain":
        return "assets/rainy.json";
      case "thunderstorm":
        return "assets/thunder.json";
      case "clear":
        return "assets/sunny.json";
      default:
        return "assets/sunny.json";
    }
  }

  String getWeatherCondition(String? mainCondition) {
    if (mainCondition == null) {
      return "Sunny";
    }

    switch (mainCondition.toLowerCase()) {
      case "clouds":
        return "Cloudy";
      case "rain":
        return "Rainy";
      case "thunderstorm":
        return "Thunderstorm";
      case "clear":
        return "Clear Sky";
      default:
        return "Sunny";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[400],
      body: RefreshIndicator(
        onRefresh: _fetchWeather,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: _isLoading
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            'Fetching weather...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : _errorMessage.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _fetchWeather,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.cyan,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : WeatherContent(
                            weather: _weather,
                            getWeatherCondition: getWeatherCondition,
                            getWeatherConditionAsset: getWeatherConditionAsset,
                            onRefresh: _fetchWeather,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherContent extends StatelessWidget {
  final Weather? weather;
  final String Function(String?) getWeatherCondition;
  final String Function(String?) getWeatherConditionAsset;
  final VoidCallback onRefresh;

  const WeatherContent({
    super.key,
    required this.weather,
    required this.getWeatherCondition,
    required this.getWeatherConditionAsset,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          elevation: 8,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color.fromARGB(255, 151, 213, 241).withOpacity(0.9),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather?.cityName ?? "Loading city",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          getWeatherCondition(weather?.mainCondition),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Lottie.asset(
                    getWeatherConditionAsset(weather?.mainCondition),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${weather?.temperature.round() ?? "--"}°C',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
