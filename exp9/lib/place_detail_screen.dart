// lib/place_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'place_model.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  Place? place;
  String? description;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (place == null) {
      place = ModalRoute.of(context)!.settings.arguments as Place;
      _fetchDescription(place!.name);
    }
  }

  Future<void> _fetchDescription(String placeName) async {
    final url = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(placeName)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['extract'] != null) {
          setState(() {
            description = data['extract'];
          });
        } else {
          setState(() {
            description = 'Description not available.';
          });
        }
      } else {
        setState(() {
          description = 'Description not available.';
        });
      }
    } catch (_) {
      setState(() {
        description = 'Description not available.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place!.name),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Image.network(
            place!.image,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10),
          Text("📍 ${place!.country}",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: description == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Text(
                        description!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
