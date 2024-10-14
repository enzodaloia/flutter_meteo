import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_meteo/models/constants.dart';
import 'package:projet_meteo/widgets/weather_item.dart';

// Définir les maps directement ici
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

class DetailPage extends StatefulWidget {
  final List consolidatedWeatherList;
  final int selectedId;
  final String location;

  const DetailPage(
      {Key? key,
      required this.consolidatedWeatherList,
      required this.selectedId,
      required this.location})
      : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String imageUrl = '';

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    Constants myConstants = Constants();

    //Create a shader linear gradient
    final Shader linearGradient = const LinearGradient(
      colors: <Color>[Color(0xffABCFF2), Color(0xff9AC6F3)],
    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

    int selectedIndex = widget.selectedId;
    var selectedWeather = widget.consolidatedWeatherList[selectedIndex];
    var weatherStateName =
        weatherDescriptions[selectedWeather['weathercode']] ?? 'Unknown';
    imageUrl =
        weatherImages[selectedWeather['weathercode']] ?? 'default_weather';

    return Scaffold(
      backgroundColor: myConstants.secondaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myConstants.secondaryColor,
        elevation: 0.0,
        title: Text(widget.location),
      ),
      body: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              height: size.height * .55,
              width: size.width,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    topLeft: Radius.circular(50),
                  )),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -250,
                    right: 20,
                    left: 20,
                    child: Container(
                      width: size.width * .7,
                      height: 300,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.center,
                              colors: [
                                Color(0xffa9c1f5),
                                Color(0xff6696f5),
                              ]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(.1),
                              offset: const Offset(0, 25),
                              blurRadius: 3,
                              spreadRadius: -10,
                            ),
                          ]),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -40,
                            left: 20,
                            child: Image.asset(
                              'assets/$imageUrl.png',
                              width: 150,
                            ),
                          ),
                          Positioned(
                              top: 120,
                              left: 30,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  weatherStateName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              )),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: Container(
                              width: size.width * .8,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  weatherItem(
                                    text: 'Vitesse du vent',
                                    value: (selectedWeather['wind_speed'] ?? 0)
                                        .round(),
                                    unit: 'km/h',
                                    imageUrl: 'assets/windspeed.png',
                                  ),
                                  weatherItem(
                                      text: 'Humidité',
                                      value: (selectedWeather['humidity'] ?? 0)
                                          .round(),
                                      unit: '%',
                                      imageUrl: 'assets/humidity.png'),
                                  weatherItem(
                                    text: 'Temp. max',
                                    value: (selectedWeather['maxTemp'] ?? 0)
                                        .round(),
                                    unit: 'C',
                                    imageUrl: 'assets/max-temp.png',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${selectedWeather['maxTemp'].round()}',
                                  style: TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..shader = linearGradient,
                                  ),
                                ),
                                Text(
                                  'o',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..shader = linearGradient,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 20,
                    child: SizedBox(
                      height: 300,
                      width: size.width * .9,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: widget.consolidatedWeatherList.length,
                        itemBuilder: (BuildContext context, int index) {
                          var futureWeather =
                              widget.consolidatedWeatherList[index];
                          var futureWeatherName = weatherDescriptions[
                                  futureWeather['weathercode']] ??
                              'Unknown';
                          var futureImageURL =
                              weatherImages[futureWeather['weathercode']] ??
                                  'default_weather';
                          var myDate = DateTime.parse(futureWeather['time'] ??
                              DateTime.now()
                                  .toString()); // Assurez-vous que le champ 'time' existe
                          var currentDate = DateFormat('d MMMM, HH:mm')
                              .format(myDate); // Format heure par heure

                          return Container(
                            margin: const EdgeInsets.only(
                                left: 10, top: 10, right: 10, bottom: 5),
                            height: 80,
                            width: size.width,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                  color: myConstants.secondaryColor
                                      .withOpacity(.1),
                                  spreadRadius: 5,
                                  blurRadius: 20,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    currentDate,
                                    style: const TextStyle(
                                      color: Color(0xff6696f5),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${futureWeather['temperature']?.round() ?? 0}', // Assurez-vous que le champ 'temperature' existe
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Text(
                                        '/',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 30,
                                        ),
                                      ),
                                      Text(
                                        '${futureWeather['minTemp']?.round() ?? 0}', // Assurez-vous que le champ 'minTemp' existe
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 25,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/$futureImageURL.png',
                                        width: 30,
                                      ),
                                      Text(futureWeatherName),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
