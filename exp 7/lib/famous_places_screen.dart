// lib/famous_places_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'place_model.dart';
import 'firestore_helper.dart';

class FamousPlacesScreen extends StatefulWidget {
  const FamousPlacesScreen({super.key});

  @override
  State<FamousPlacesScreen> createState() => _FamousPlacesScreenState();
}

class _FamousPlacesScreenState extends State<FamousPlacesScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  final bool _showList = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();

  final List<Place> places = [];

  @override
  void initState() {
    super.initState();
    _loadPlacesFromDB();
  }

  Future<void> _loadPlacesFromDB() async {
    final dbPlaces = await FirestoreHelper.getAllPlaces();
    setState(() {
      places.clear();
      places.addAll(dbPlaces);
    });
  }

  void _moveToPlace(Place place) {
    setState(() {
      _markers = [
        Marker(
          point: place.latLng,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        )
      ];
    });

    _mapController.move(place.latLng, 14);
  }

  Future<LatLng?> _getCoordinates(String address) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1");

    try {
      final response = await http.get(url, headers: {"User-Agent": "Flutter App"});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          return LatLng(
            double.parse(data[0]["lat"]),
            double.parse(data[0]["lon"]),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  // ✅ POST–Wikipedia fallback image
  static const fallbackImage =
      "https://via.placeholder.com/600x400.png?text=No+Image";

  // ✅ (1) Wikipedia summary API
  Future<String?> _wikiSummary(String name) async {
    try {
      final url = Uri.parse(
        "https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(name)}",
      );

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data["thumbnail"]?["source"] != null) {
          return data["thumbnail"]["source"];
        }
      }
    } catch (_) {}
    return null;
  }

  // ✅ (2) Wikipedia PageImages API
  Future<String?> _wikiPageImage(String name) async {
    try {
      final url = Uri.parse(
        "https://en.wikipedia.org/w/api.php?action=query&titles=${Uri.encodeComponent(name)}&prop=pageimages&pithumbsize=800&format=json"
      );

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final pages = data["query"]["pages"] as Map;
        final page = pages.values.first;

        if (page["thumbnail"]?["source"] != null) {
          return page["thumbnail"]["source"];
        }
      }
    } catch (_) {}
    return null;
  }

  /// ✅ FINAL FREE IMAGE FETCHER
  Future<String> _getAutoImage(String name) async {
    final img1 = await _wikiSummary(name);
    if (img1 != null) return img1;

    final img2 = await _wikiPageImage(name);
    if (img2 != null) return img2;

    return fallbackImage;
  }

  Future<void> _addPlace() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final country = _countryController.text.trim();

    final address = "$name $country";

    final coords = await _getCoordinates(address);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Unable to find location")),
      );
      return;
    }

    final imgUrl = await _getAutoImage(name);

    final newPlace = Place(
      name: name,
      country: country,
      image: imgUrl,
      latLng: coords,
    );

    setState(() {
      places.add(newPlace);
    });

    await FirestoreHelper.addPlace(newPlace);

    _nameController.clear();
    _countryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌍 Famous Places Map"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),

      body: Column(
        children: [
          // 🔹 MAP
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(20.5937, 78.9629),
                initialZoom: 2,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),

          // 🔹 LIST + FORM
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final p = places[index];
                      return Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,

                              errorBuilder: (_, __, ___) {
                                return Image.network(
                                  fallbackImage,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Text(p.country),
                          onTap: () => _moveToPlace(p),
                        ),
                      );
                    },
                  ),
                ),

                // ✅ ADD PLACE FORM
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Place Name",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Enter place name" : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: "Country",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? "Enter country" : null,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _addPlace,
                          child: const Text("Add Place"),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
