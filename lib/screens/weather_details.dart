import 'dart:convert';
import 'dart:io';

import 'package:assessment_mtss/model/weather_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherDetails extends StatefulWidget {
  final Map<dynamic, dynamic> data;
  const WeatherDetails({super.key, required this.data});

  @override
  _WeatherDetailsState createState() => _WeatherDetailsState();
}

class _WeatherDetailsState extends State<WeatherDetails> {
  Future<WeatherModel>? futureWeather;
  //TODO: Add your api key
  String apiKey = 'your api key';
  final TextEditingController _cityNameController = TextEditingController();

  Future<WeatherModel> fetchData(String cityName) async {
    final response = await http.get(Uri.parse(
        'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$cityName&aqi=no'));

    if (response.statusCode == 200) {
      return weatherModelFromJson(response.body);
    } else {
      throw Exception('Invalid name');
    }
  }

  Future<void> saveWeatherData(String cityname, double temp) async {
    const url = 'http://127.0.0.1:5000/save_weather';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"cityname": cityname, "temp": temp}),
    );
    if (response.statusCode == 201) {
      print('Weather data saved: ${response.body}');
    } else {
      print('Failed to save weather data: ${response.reasonPhrase}');
    }
  }

  @override
  void dispose() {
    _cityNameController.dispose();
    super.dispose();
  }

  void _fetchWeather() {
    if (_cityNameController.text.isNotEmpty) {
      setState(() {
        futureWeather = fetchData(_cityNameController.text);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello ${widget.data['name']}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: widget.data['profilePic'] == null
                  ? const AssetImage('assets/images/profile.png')
                  : FileImage(File(widget.data['profilePic'])),
              backgroundColor: Colors.grey[200],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: const Text(
              'Weather Detector',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Enter city name'),
              controller: _cityNameController,
            ),
          ),
          ElevatedButton(
            onPressed: _fetchWeather,
            child: const Text('Submit'),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<WeatherModel>(
              future: futureWeather,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  WeatherModel? weatherData = snapshot.data;
                  print(weatherData?.current?.condition?.icon);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Location: ${weatherData?.location?.name}, ${weatherData?.location?.country}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Temperature: ${weatherData?.current?.tempC}°C',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      if (weatherData?.current?.condition != null)
                        Text(
                          'Condition: ${weatherData?.current?.condition?.text}',
                          style: const TextStyle(fontSize: 20),
                        ),
                      if (weatherData?.current?.condition?.icon != null)
                        Image.network(
                          'https:${weatherData?.current?.condition?.icon}',
                          height: 50,
                          width: 50,
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          saveWeatherData(weatherData!.location!.name!,
                              weatherData.current!.tempC!);
                        },
                        child: const Text('Save to Database'),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: Text(''));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
