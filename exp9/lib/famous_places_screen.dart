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
  final _searchController = TextEditingController();

  final List<Place> places = [];
  final fallbackImage = "https://via.placeholder.com/600x400.png?text=No+Image";

  @override
  void initState() {
    super.initState();
    _loadPlacesFromDB();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlacesFromDB() async {
    try {
      final dbPlaces = await FirestoreHelper.getAllPlaces();
      setState(() {
        places.clear();
        places.addAll(dbPlaces);
      });
      debugPrint("Loaded ${dbPlaces.length} places from Firestore");
    } catch (e) {
      debugPrint("Error loading places: $e");
    }
  }

  Future<void> _searchPlace() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      await _loadPlacesFromDB();
      return;
    }

    try {
      final results = await FirestoreHelper.searchPlaces(keyword);
      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No matching place found")),
          );
        }
        return;
      }
      setState(() {
        places.clear();
        places.addAll(results);
      });
      _moveToPlace(results.first);
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  void _moveToPlace(Place place) {
    debugPrint("Moving to place: ${place.name} id=${place.id}");
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

  Future<void> _addPlace() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final country = _countryController.text.trim();
    final address = "$name $country";

    final coords = await _getCoordinates(address);
    if (coords == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Unable to find location")));
      }
      return;
    }

    final imgUrl = await _getAutoImage(name);

    try {
      final docRef = await FirestoreHelper.addPlaceAndGetRef(
        Place(name: name, country: country, image: imgUrl, latLng: coords),
      );

      final newLocal = Place(
        id: docRef.id,
        name: name,
        country: country,
        image: imgUrl,
        latLng: coords,
      );

      setState(() {
        places.add(newLocal);
      });

      _nameController.clear();
      _countryController.clear();
      debugPrint("Added place ${newLocal.name} id=${newLocal.id}");
    } catch (e) {
      debugPrint("Add error: $e");
    }
  }

  Future<LatLng?> _getCoordinates(String address) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1");

    try {
      final res = await http.get(url, headers: {"User-Agent": "Flutter App"});
      final data = json.decode(res.body);
      if (data is List && data.isNotEmpty) {
        return LatLng(
          double.parse(data[0]["lat"].toString()),
          double.parse(data[0]["lon"].toString()),
        );
      }
    } catch (e) {
      debugPrint("Nominatim error: $e");
    }
    return null;
  }

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
    } catch (e) {
      debugPrint("Wiki image error: $e");
    }
    return fallbackImage;
  }

  /// NEW: Bottom sheet that is clearly visible and draggable
  Future<void> _openEditBottomSheet(Place place) async {
    debugPrint("Opening bottom sheet for ${place.name} id=${place.id}");
    final editNameCtrl = TextEditingController(text: place.name);
    final editCountryCtrl = TextEditingController(text: place.country);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.38,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Edit Place", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),

                    // Image preview
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: Image.network(
                            place.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Image.network(fallbackImage, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: editNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Place Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: editCountryCtrl,
                      decoration: const InputDecoration(
                        labelText: "Country",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final newName = editNameCtrl.text.trim();
                              final newCountry = editCountryCtrl.text.trim();
                              if (newName.isEmpty || newCountry.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Name & country required")),
                                );
                                return;
                              }

                              final updated = Place(
                                id: place.id,
                                name: newName,
                                country: newCountry,
                                image: place.image,
                                latLng: place.latLng,
                              );

                              try {
                                await FirestoreHelper.updatePlace(updated);
                                // update local list in-place
                                final idx = places.indexWhere((e) => e.id == place.id);
                                if (idx != -1) {
                                  setState(() {
                                    places[idx] = updated;
                                  });
                                } else {
                                  // If not found, reload all
                                  await _loadPlacesFromDB();
                                }
                                Navigator.pop(context);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text("Place updated")),
                                );
                                debugPrint("Updated place ${updated.id}");
                              } catch (e) {
                                debugPrint("Update error: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Update failed: $e")),
                                );
                              }
                            },
                            child: const Text("UPDATE"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("CANCEL"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    editNameCtrl.dispose();
    editCountryCtrl.dispose();
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
          // SEARCH BAR
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

          // MAP
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(20.5937, 78.9629),
                initialZoom: 2,
              ),
              children: [
                TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),

          // LIST + FORM
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPlacesFromDB,
                    child: ListView.builder(
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final p = places[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p.image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Image.network(fallbackImage, width: 60, height: 60),
                              ),
                            ),
                            title: Text(p.name),
                            subtitle: Text(p.country),
                            onTap: () async {
                              debugPrint("ListTile tapped: ${p.name} id=${p.id}");
                              _moveToPlace(p);
                              // open bottom sheet after a tiny delay to ensure map movement starts
                              await Future.delayed(const Duration(milliseconds: 60));
                              await _openEditBottomSheet(p);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ADD FORM
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
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Enter place name" : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: "Country",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Enter country" : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _addPlace,
                                child: const Text("Add Place"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // quick refresh button
                            OutlinedButton(
                              onPressed: _loadPlacesFromDB,
                              child: const Text("Refresh"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
