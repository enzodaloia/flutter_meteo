import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:projet_meteo/models/constants.dart';
import 'package:projet_meteo/widgets/weather_item.dart';
import 'package:projet_meteo/ui/detail_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String imageUrl = '';
  double temperature = 0.0;
  double maxTemp = 0.0;
  String weatherStateName = 'Chargement...';
  int humidity = 0;
  double windSpeed = 0.0;
  final TextEditingController _controller = TextEditingController();
  String _cityName = 'Chargement du nom de votre ville...';
  List<dynamic> forecastList = [];
  bool isCelsius = true;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _fetchWeatherByLocation();
    _initializeNotifications();

    Future.delayed(Duration(seconds: 2), () {
      showNotification(
          "Test Notification", "Ceci est un test de notification.");
    });
  }

  Future<void> _initializeNotifications() async {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Mapping des codes météo d'Open-Meteo vers des descriptions
  final Map<int, String> weatherDescriptions = {
    0: 'Ciel dégagé',
    1: 'Principalement dégagé',
    2: 'Partiellement nuageux',
    3: 'Couvert',
    45: 'Brouillard',
    48: 'Brouillard givrant',
    51: 'Bruine légère',
    53: 'Bruine modérée',
    55: 'Bruine dense',
    56: 'Bruine verglaçante légère',
    57: 'Bruine verglaçante dense',
    61: 'Pluie légère',
    63: 'Pluie modérée',
    65: 'Pluie forte',
    66: 'Pluie verglaçante légère',
    67: 'Pluie verglaçante forte',
    71: 'Neige légère',
    73: 'Neige modérée',
    75: 'Neige forte',
    77: 'Grains de neige',
    80: 'Averses de pluie légère',
    81: 'Averses de pluie modérée',
    82: 'Averses de pluie violente',
    85: 'Averses de neige légère',
    86: 'Averses de neige forte',
    95: 'Orage modéré',
    96: 'Orage avec grêle légère',
    99: 'Orage avec grêle forte',
  };

  // Mapping des codes météo d'Open-Meteo vers les noms de fichiers d'images
  final Map<int, String> weatherImages = {
    0: 'cieldégagé',
    1: 'cieldégagé',
    2: 'peunuageux',
    3: 'couvert',
    45: 'brouillard',
    48: 'hail',
    51: 'peunuageux',
    53: 'brouillard',
    55: 'brouillard',
    56: 'hail',
    57: 'hail',
    61: 'légèrepluie',
    63: 'pluiemodérée',
    65: 'pluiemodérée',
    66: 'hail',
    67: 'heavyrain',
    71: 'hail',
    73: 'hail',
    75: 'hail',
    77: 'hail',
    80: 'légèrepluie',
    81: 'légèrepluie',
    82: 'légèrepluie',
    85: 'hail',
    86: 'hail',
    95: 'thunderstorm',
    96: 'thunderstorm',
    99: 'heavyrain',
  };

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

  // Méthode pour obtenir la météo en fonction de la longitude et de la latitude
  Future<void> _fetchWeatherByCoords(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=relativehumidity_2m&daily=temperature_2m_max,weathercode&timezone=auto&language=fr');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['current_weather'] == null) {
          setState(() {
            _cityName = 'Données météo non disponibles';
          });
          return;
        }

        final currentWeather = data['current_weather'];
        final weathercode = currentWeather['weathercode'] as int;
        final temperature = (currentWeather['temperature'] as num).toDouble();
        final windSpeed = (currentWeather['windspeed'] as num).toDouble();
        final time = currentWeather['time'];

        final hourly = data['hourly'];
        if (hourly == null) {
          setState(() {
            _cityName = 'Données météo horaire non disponibles';
          });
          return;
        }

        final hourlyTimes = List<String>.from(hourly['time'] ?? []);
        final humidityValues =
            List<dynamic>.from(hourly['relativehumidity_2m'] ?? []);
        int humidity = 0;

        int index = hourlyTimes.indexOf(time);
        if (index != -1 && index < humidityValues.length) {
          humidity = (humidityValues[index] as num).round();
        }

        final daily = data['daily'];
        List<dynamic> forecastListTemp = [];

        if (daily != null &&
            daily['temperature_2m_max'] != null &&
            daily['weathercode'] != null &&
            daily['time'] != null) {
          final dailyMaxTemps = List<dynamic>.from(daily['temperature_2m_max']);
          final dailyTimes = List<String>.from(daily['time']);
          final dailyWeatherCodes = List<dynamic>.from(daily['weathercode']);

          forecastListTemp = List.generate(dailyMaxTemps.length, (i) {
            return {
              'date': dailyTimes[i],
              'maxTemp': (dailyMaxTemps[i] as num).toDouble(),
              'weathercode': (dailyWeatherCodes[i] as num).toInt(),
            };
          });
        }

        String weatherDescription =
            weatherDescriptions[weathercode] ?? 'Données météo indisponibles';
        String imageUrl = weatherImages[weathercode] ?? 'default_weather';

        // Obtenir le nom de la ville à partir des coordonnées
        String cityName = await _getCityNameFromCoords(lat, lon);

        setState(() {
          _cityName = cityName;
          this.temperature = temperature;
          weatherStateName = weatherDescription;
          this.humidity = humidity;
          this.windSpeed = windSpeed;
          this.maxTemp = forecastListTemp.isNotEmpty
              ? forecastListTemp[0]['maxTemp']
              : 0.0;
          this.imageUrl = imageUrl;
          forecastList = forecastListTemp; // Stockage des prévisions
        });

        checkForRainOrStorm(forecastListTemp);
      } else {
        setState(() {
          _cityName = 'Données météo non disponibles';
        });
      }
    } catch (e) {
      setState(() {
        _cityName = 'Erreur de récupération des données';
      });
    }
  }

  // Méthode pour obtenir le nom de la ville en fonction des coordonnés avec l'api openstreetmap car je ne l'a trouve pas dans open meteo
  Future<String> _getCityNameFromCoords(double lat, double lon) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1&accept-language=fr');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final city = data['address']['city'] ??
              data['address']['town'] ??
              data['address']['village'] ??
              'Ville inconnue';
          return city;
        }
      }
    } catch (e) {
      return 'Ville inconnue';
    }
    return 'Ville inconnue';
  }

  // Méthode pour faire une requête API Open-Meteo avec le nom de la ville trouvé grâce openstreetmap
  Future<void> _fetchWeatherByCity(String city) async {
    final geocodingUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=fr&format=json');

    try {
      final geocodingResponse = await http.get(geocodingUrl);

      if (geocodingResponse.statusCode == 200) {
        final geocodingData = json.decode(geocodingResponse.body);

        if (geocodingData['results'] != null &&
            geocodingData['results'].isNotEmpty) {
          final firstResult = geocodingData['results'][0];
          final lat = firstResult['latitude'];
          final lon = firstResult['longitude'];
          final cityName = firstResult['name'] ?? 'Ville inconnue';

          final url = Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=relativehumidity_2m&daily=temperature_2m_max,weathercode&timezone=auto&language=fr');

          final weatherResponse = await http.get(url);

          if (weatherResponse.statusCode == 200) {
            final weatherData = json.decode(weatherResponse.body);

            if (weatherData['current_weather'] == null) {
              setState(() {
                _cityName = 'Données météo non disponibles';
              });
              return;
            }

            final currentWeather = weatherData['current_weather'];
            final weathercode = currentWeather['weathercode'] as int;
            final temperature =
                (currentWeather['temperature'] as num).toDouble();
            final windSpeed = (currentWeather['windspeed'] as num).toDouble();
            final time = currentWeather['time'];

            final hourly = weatherData['hourly'];
            if (hourly == null) {
              setState(() {
                _cityName = 'Données météo horaire non disponibles';
              });
              return;
            }

            final hourlyTimes = List<String>.from(hourly['time'] ?? []);
            final humidityValues =
                List<dynamic>.from(hourly['relativehumidity_2m'] ?? []);
            int humidity = 0;

            int index = hourlyTimes.indexOf(time);
            if (index != -1 && index < humidityValues.length) {
              humidity = (humidityValues[index] as num).round();
            }

            final daily = weatherData['daily'];
            List<dynamic> forecastListTemp = [];
            if (daily != null &&
                daily['temperature_2m_max'] != null &&
                daily['weathercode'] != null &&
                daily['time'] != null) {
              final dailyMaxTemps =
                  List<dynamic>.from(daily['temperature_2m_max']);
              final dailyTimes = List<String>.from(daily['time']);
              final dailyWeatherCodes =
                  List<dynamic>.from(daily['weathercode']);

              forecastListTemp = List.generate(dailyMaxTemps.length, (i) {
                return {
                  'date': dailyTimes[i],
                  'maxTemp': (dailyMaxTemps[i] as num).toDouble(),
                  'weathercode': (dailyWeatherCodes[i] as num).toInt(),
                };
              });
            }

            String weatherDescription = weatherDescriptions[weathercode] ??
                'Données météo indisponibles';
            String imageUrl = weatherImages[weathercode] ?? 'default_weather';

            setState(() {
              _cityName = cityName;
              this.temperature = temperature;
              weatherStateName = weatherDescription;
              this.humidity = humidity;
              this.windSpeed = windSpeed;
              this.maxTemp = forecastListTemp.isNotEmpty
                  ? forecastListTemp[0]['maxTemp']
                  : 0.0;
              this.imageUrl = imageUrl;
              forecastList = forecastListTemp;
            });
          } else {
            setState(() {
              _cityName = 'Données météo non disponibles';
            });
          }
        } else {
          setState(() {
            _cityName = 'Ville non trouvée';
          });
        }
      } else {
        setState(() {
          _cityName = 'Erreur de géocodage';
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des données météo par ville : $e');
      setState(() {
        _cityName = 'Erreur de récupération des données';
      });
    }
  }

  // Méthode pour convertir en degrés Celsius ou Fahrenheit
  double _convertCelsiusToFahrenheit(double celsius) {
    return celsius * 9 / 5 + 32;
  }

  // Méthode qui permet d'avoir l'unité en celsius ou en fahrenheit
  void _toggleTemperatureUnit() {
    setState(() {
      if (isCelsius) {
        temperature = _convertCelsiusToFahrenheit(temperature);
        maxTemp = _convertCelsiusToFahrenheit(maxTemp);
      } else {
        temperature = (temperature - 32) * 5 / 9;
        maxTemp = (maxTemp - 32) * 5 / 9;
      }
      isCelsius = !isCelsius;
    });
  }

  // Méthode qui est censé m'afficher une notif, que j'utilise pour la pluie ou l'orage
  void showNotification(String title, String body) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channel_id', 'channel_name',
            channelDescription: 'description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  // Méthode qui check s'il y a de la pluie ou de l'orage
  void checkForRainOrStorm(List forecastList) {
    bool hasRain = false;
    bool hasStorm = false;

    for (var dayForecast in forecastList) {
      int weatherCode = dayForecast['weathercode'];

      if ([51, 53, 55, 61, 63, 65, 66, 67, 80, 81, 82].contains(weatherCode)) {
        hasRain = true;
        break;
      }
      if ([95, 96, 99].contains(weatherCode)) {
        hasStorm = true;
        break;
      }
    }

    if (hasRain) {
      showNotification("Alerte météo", "Pluie prévus cette semaine.");
    }
    if (hasStorm) {
      showNotification("Alerte météo", "Orage prévus cette semaine.");
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
              _fetchWeatherByCity(value);
            }
          },
          style: const TextStyle(color: Colors.black),
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
                    top: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: _toggleTemperatureUnit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isCelsius ? 'Convertir en °F' : 'Convertir en °C',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                    top: 60,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${temperature.round()}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          isCelsius ? '°C' : '°F',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  weatherItem(
                      value: windSpeed.round(),
                      text: 'Vitesse du vent',
                      unit: ' km/h',
                      imageUrl: 'assets/windspeed.png'),
                  weatherItem(
                      value: humidity,
                      text: 'Humidité',
                      unit: '%',
                      imageUrl: 'assets/humidity.png'),
                  weatherItem(
                      value: maxTemp.round(),
                      text: 'Temp. max',
                      unit: isCelsius ? '°C' : '°F',
                      imageUrl: 'assets/max-temp.png'),
                ],
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Aujourd\'hui',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  '7 prochains jours',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: myConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: forecastList.length < 7
                    ? forecastList.length
                    : 7, // Limiter à 7 jours
                itemBuilder: (BuildContext context, int index) {
                  String today = DateTime.now().toString().substring(0, 10);

                  // Récupération des données pour le jour actuel
                  var selectedDay = forecastList[index]['date'];
                  var futureWeatherName =
                      weatherDescriptions[forecastList[index]['weathercode']];
                  var weatherUrl = (futureWeatherName != null)
                      ? weatherImages[forecastList[index]['weathercode']] ??
                          'default_weather'
                      : 'default_weather';

                  // Conversion de la date au format lisible
                  var parsedDate = DateTime.parse(selectedDay);
                  var newDate =
                      DateFormat('EEEE').format(parsedDate).substring(0, 3);

                  // Température maximale pour la journée
                  var maxTemp = isCelsius
                      ? forecastList[index]['maxTemp'].round()
                      : (forecastList[index]['maxTemp'] * 9 / 5 + 32).round();

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            consolidatedWeatherList: forecastList,
                            selectedId: index,
                            location: _cityName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      margin:
                          const EdgeInsets.only(right: 20, bottom: 10, top: 10),
                      width: 80,
                      decoration: BoxDecoration(
                        color: selectedDay == today
                            ? myConstants.primaryColor
                            : Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 1),
                            blurRadius: 5,
                            color: selectedDay == today
                                ? myConstants.primaryColor
                                : Colors.black54.withOpacity(.2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Affichage de la température maximale
                          Text(
                            '$maxTemp${isCelsius ? '°C' : '°F'}', // Température avec unité
                            style: TextStyle(
                              fontSize: 17,
                              color: selectedDay == today
                                  ? Colors.white
                                  : myConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Icône météo
                          Image.asset(
                            'assets/$weatherUrl.png',
                            width: 25,
                          ),
                          // Jour de la semaine (abrégé)
                          Text(
                            newDate,
                            style: TextStyle(
                              fontSize: 17,
                              color: selectedDay == today
                                  ? Colors.white
                                  : myConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
