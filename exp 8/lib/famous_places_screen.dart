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

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();

  /// ✅ NEW
  final TextEditingController _searchController = TextEditingController();

  final List<Place> places = [];

  final fallbackImage =
      "https://via.placeholder.com/600x400.png?text=No+Image";

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

  /// ✅ SEARCH FIRESTORE
  Future<void> _searchPlace() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    final results = await FirestoreHelper.searchPlaces(keyword);

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No matching place found")),
      );
      return;
    }

    setState(() {
      places.clear();
      places.addAll(results);
    });

    _moveToPlace(results.first);
  }

  void _moveToPlace(Place place) {
    setState(() {
      _markers = [
        Marker(
          point: place.latLng,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ];
    });
    _mapController.move(place.latLng, 14);
  }

  // ✅ SAME Wikipedia image function
  Future<String> _getAutoImage(String placeName) async {
    try {
      final url = Uri.parse(
          "https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(placeName)}");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data["thumbnail"]?["source"] != null) {
          return data["thumbnail"]["source"];
        }
      }
    } catch (_) {}

    return fallbackImage;
  }

  Future<LatLng?> _getCoordinates(String address) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1");

    try {
      final res =
          await http.get(url, headers: {"User-Agent": "Flutter App"});
      final data = json.decode(res.body);
      if (data.isNotEmpty) {
        return LatLng(
          double.parse(data[0]["lat"]),
          double.parse(data[0]["lon"]),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _addPlace() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final country = _countryController.text.trim();
    final address = "$name $country";

    final coords = await _getCoordinates(address);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to find location")),
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
      ),

      body: Column(
        children: [
          /// ✅ SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Search Place",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchPlace,
                  child: const Text("Search"),
                ),
              ],
            ),
          ),

          /// ✅ MAP
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(20.5937, 78.9629),
                initialZoom: 2,
              ),
              children: [
                TileLayer(urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),

          /// ✅ PLACE LIST + FORM
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
                          leading: Image.network(
                            p.image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Image.network(fallbackImage),
                          ),
                          title: Text(p.name),
                          subtitle: Text(p.country),
                          onTap: () => _moveToPlace(p),
                        ),
                      );
                    },
                  ),
                ),

                /// ADD PLACE FORM
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: "Place Name",
                              border: OutlineInputBorder()),
                          validator: (v) =>
                              v!.isEmpty ? "Enter place name" : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                              labelText: "Country",
                              border: OutlineInputBorder()),
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
