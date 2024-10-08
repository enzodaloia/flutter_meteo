import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:projet_meteo/models/constants.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String imageUrl = '';
  int temperature = 0;
  int maxTemp = 0;
  String weatherStateName = 'Loading...';
  int humidity = 0;
  int windSpeed = 0;
  final TextEditingController _controller = TextEditingController();
  String _cityName = 'Chargement du nom de votre ville...';
  final String _apiKey =
      'ad112961462d966845c4778364ea256c'; // Remplace par ta clé API OpenWeather

  @override
  void initState() {
    super.initState();
    _fetchWeatherByLocation(); // Obtenir les infos météo en fonction de la localisation actuelle au démarrage
  }

  // Méthode pour obtenir la position actuelle
  Future<void> _fetchWeatherByLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _cityName = 'Les services de localisation sont désactivés.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _cityName =
              'Les permissions de localisation sont définitivement refusées.';
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _cityName = 'Les permissions de localisation sont refusées.';
        });
        return;
      }
    }

    final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _fetchWeatherByCoords(position.latitude, position.longitude);
  }

  // Méthode pour faire une requête API avec latitude et longitude
  Future<void> _fetchWeatherByCoords(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=fr');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _cityName = data['name'] ?? 'Ville inconnue';
          temperature = (data['main']['temp'] as num).round();
          weatherStateName = data['weather'][0]['description'] ??
              'Données météo indisponibles';
          humidity = (data['main']['humidity'] as num).round();
          windSpeed = (data['wind']['speed'] as num).round();
          maxTemp = (data['main']['temp_max'] as num).round();

          imageUrl = weatherStateName.replaceAll(' ', '').toLowerCase();
        });
      } else {
        setState(() {
          _cityName = 'Ville non trouvée';
        });
      }
    } catch (e) {
      setState(() {
        _cityName = 'Erreur de récupération des données';
      });
    }
  }

  // Méthode pour faire une requête API avec le nom de la ville
  Future<void> _fetchWeatherByCity(String city) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey&units=metric&lang=fr');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _cityName = data['name'] ?? 'Ville inconnue';
          temperature = (data['main']['temp'] as num).round();
          weatherStateName = data['weather'][0]['description'] ??
              'Données météo indisponibles';
          humidity = (data['main']['humidity'] as num).round();
          windSpeed = (data['wind']['speed'] as num).round();
          maxTemp = (data['main']['temp_max'] as num).round();

          imageUrl = weatherStateName.replaceAll(' ', '').toLowerCase();
        });
      } else {
        setState(() {
          _cityName = 'Ville non trouvée';
        });
      }
    } catch (e) {
      setState(() {
        _cityName = 'Erreur de récupération des données';
      });
    }
  }

  final Shader linearGradient = const LinearGradient(
    colors: <Color>[Color(0xffABCFF2), Color(0x0ff9c6f3)],
  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

  @override
  Widget build(BuildContext context) {
    Constants myConstants = Constants();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Rechercher une ville',
            hintText: 'Entrez une ville',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _fetchWeatherByCity(
                  value); // Remplace fetchWeatherData par _fetchWeatherByCity
            }
          },
          style: const TextStyle(
              color: Colors.white), // Texte visible sur l'AppBar
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              _cityName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM y').format(DateTime.now()),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 50),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 200,
              decoration: BoxDecoration(
                color: myConstants.primaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: myConstants.primaryColor.withOpacity(.5),
                    offset: const Offset(0, 25),
                    spreadRadius: -12,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -40,
                    left: 20,
                    child: imageUrl.isNotEmpty
                        ? Image.asset('assets/$imageUrl.png', width: 150)
                        : Container(),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    child: Text(
                      weatherStateName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '$temperature',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
