// lib/famous_places_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'place_model.dart';




class FamousPlacesScreen extends StatefulWidget {
  const FamousPlacesScreen({super.key});

  @override
  State<FamousPlacesScreen> createState() => _FamousPlacesScreenState();
}

class _FamousPlacesScreenState extends State<FamousPlacesScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  bool _showList = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _imageController = TextEditingController();

  final List<Place> places = [
    Place(
      name: 'Taj Mahal',
      country: 'India',
      image: 'https://upload.wikimedia.org/wikipedia/commons/d/da/Taj-Mahal.jpg',
      latLng: LatLng(27.1751, 78.0421),
    ),
    Place(
      name: 'Eiffel Tower',
      country: 'France',
      image:
          'https://upload.wikimedia.org/wikipedia/commons/a/a8/Tour_Eiffel_Wikimedia_Commons.jpg',
      latLng: LatLng(48.8584, 2.2945),
    ),
    Place(
      name: 'Statue of Liberty',
      country: 'USA',
      image:
          'https://upload.wikimedia.org/wikipedia/commons/a/a1/Statue_of_Liberty_7.jpg',
      latLng: LatLng(40.6892, -74.0445),
    ),
  ];

  void _moveToPlace(Place place) {
    setState(() {
      _markers = [
        Marker(
          point: place.latLng,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, size: 40, color: Colors.red),
        ),
      ];
    });
    _mapController.move(place.latLng, 14);
  }

  void _goToDetails(Place place) {
    Navigator.pushNamed(context, '/details', arguments: place);
  }

  void _showPlaceDialog(Place place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(place.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(place.image,
                  height: 150, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
            Text("📍 ${place.country}",
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _moveToPlace(place);
            },
            child: const Text("Show on Map"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToDetails(place);
            },
            child: const Text("Details"),
          ),
        ],
      ),
    );
  }

  Future<void> _addPlace() async {
    if (_formKey.currentState!.validate()) {
      final placeName = _nameController.text.trim();
      final countryName = _countryController.text.trim();

      final address = countryName.isEmpty ? placeName : '$placeName, $countryName';
      final coordinates = await _getCoordinatesFromAddress(address);
      if (coordinates == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unable to find the location")),
          );
        }
        return;
      }

      final newPlace = Place(
        name: placeName,
        country: countryName,
        image: _imageController.text.isEmpty
            ? 'https://upload.wikimedia.org/wikipedia/commons/6/65/No-Image-Placeholder.svg'
            : _imageController.text,
        latLng: coordinates,
      );

      setState(() {
        places.add(newPlace);
      });

      // fetch image from Wikipedia if not given
      if (_imageController.text.isEmpty) {
        _getImageFromWikipedia(placeName).then((imageUrl) {
          if (imageUrl != null && mounted) {
            setState(() {
              places.last =
                  Place(name: newPlace.name, country: newPlace.country, image: imageUrl, latLng: newPlace.latLng);
            });
          }
        });
      }

      _nameController.clear();
      _countryController.clear();
      _imageController.clear();
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1');
    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'Flutter App'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final firstResult = data[0];
          final lat = double.tryParse(firstResult['lat']);
          final lon = double.tryParse(firstResult['lon']);
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _getImageFromWikipedia(String placeName) async {
    final url = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(placeName)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['thumbnail'] != null && data['thumbnail']['source'] != null) {
          return data['thumbnail']['source'];
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌍 Famous Places Map"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Famous Places',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(_showList
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                        onPressed: () =>
                            setState(() => _showList = !_showList),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              place.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(place.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(place.country),
                          trailing: ElevatedButton(
                            onPressed: () => _showPlaceDialog(place),
                            child: const Text("View"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("➕ Add Your Own Place",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: "Place Name",
                              border: OutlineInputBorder()),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Enter place name"
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                              labelText: "Country",
                              border: OutlineInputBorder()),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Enter country"
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _imageController,
                          decoration: const InputDecoration(
                              labelText: "Image URL (optional)",
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton(
                            onPressed: _addPlace,
                            child: const Text("Add Place"),
                          ),
                        ),
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
