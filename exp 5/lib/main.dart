// lib/main.dart
import 'package:flutter/material.dart';
import 'famous_places_screen.dart';
import 'place_detail_screen.dart';
import 'place_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Famous Places Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const FamousPlacesScreen(),
        '/details': (context) => const PlaceDetailScreen(),
      },
    );
  }
}
