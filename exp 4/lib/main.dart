import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      home: const FamousPlacesScreen(),
    );
  }
}

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

  // Famous places
  final List<Map<String, dynamic>> places = [
    {
      'name': 'Taj Mahal',
      'country': 'India',
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/d/da/Taj-Mahal.jpg',
      'latLng': LatLng(27.1751, 78.0421),
    },
    {
      'name': 'Eiffel Tower',
      'country': 'France',
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/a/a8/Tour_Eiffel_Wikimedia_Commons.jpg',
      'latLng': LatLng(48.8584, 2.2945),
    },
    {
      'name': 'Statue of Liberty',
      'country': 'USA',
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/a/a1/Statue_of_Liberty_7.jpg',
      'latLng': LatLng(40.6892, -74.0445),
    },
  ];

  // Move to place on map
  void _moveToPlace(Map<String, dynamic> place) {
    final LatLng latLng = place['latLng'];
    setState(() {
      _markers = [
        Marker(
          point: latLng,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, size: 40, color: Colors.red),
        ),
      ];
    });
    _mapController.move(latLng, 14);
  }

  // Dialog to show details
  void _showPlaceDialog(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(place['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: place['image'].startsWith('http')
                  ? Image.network(place['image'],
                      height: 150, fit: BoxFit.cover)
                  : Container(
                      height: 150,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.location_on,
                        size: 80,
                        color: Colors.red,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text("📍 ${place['country']}",
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
        ],
      ),
    );
  }

  // Add new place using geocoding
  Future<void> _addPlace() async {
    if (_formKey.currentState!.validate()) {
      final placeName = _nameController.text.trim();
      final countryName = _countryController.text.trim();
      if (placeName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Place name cannot be empty")),
          );
        }
        return;
      }
      try {
        final address = countryName.isEmpty ? placeName : '$placeName, $countryName';
        final coordinates = await _getCoordinatesFromAddress(address);
        if (coordinates == null) {
          throw Exception("No locations found for the place");
        }
        final int newIndex = places.length;
        setState(() {
          places.add({
            'name': placeName,
            'country': countryName,
            'image': _imageController.text.isEmpty
                ? '📍'
                : _imageController.text,
            'latLng': LatLng(coordinates.latitude, coordinates.longitude),
          });
        });

        // Try to fetch image from Wikipedia if no URL provided
        if (_imageController.text.isEmpty) {
          _getImageFromWikipedia(placeName).then((imageUrl) {
            if (imageUrl != null && mounted) {
              setState(() {
                places[newIndex]['image'] = imageUrl;
              });
            }
          });
        }

        // Clear fields
        _nameController.clear();
        _countryController.clear();
        _imageController.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unable to find the location: $e")),
          );
        }
      }
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'Flutter App'});
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
    } catch (e) {
      // ignore errors here, will return null
    }
    return null;
  }

  Future<String?> _getImageFromWikipedia(String placeName) async {
    final url = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(placeName)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['thumbnail'] != null && data['thumbnail']['source'] != null) {
          return data['thumbnail']['source'];
        }
      }
    } catch (e) {
      // ignore errors
    }
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
          // Map on top
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
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
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        onPressed: () {
                          final newZoom =
                              (_mapController.camera.zoom + 1).clamp(1.0, 18.0);
                          _mapController.move(
                              _mapController.camera.center, newZoom);
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: () {
                          final newZoom =
                              (_mapController.camera.zoom - 1).clamp(1.0, 18.0);
                          _mapController.move(
                              _mapController.camera.center, newZoom);
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
                if (!_showList)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: FloatingActionButton(
                      onPressed: () => setState(() => _showList = true),
                      child: const Icon(Icons.keyboard_arrow_up),
                    ),
                  ),
              ],
            ),
          ),

          // Places List + Add Form
          if (_showList)
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
                  icon: Icon(_showList ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  onPressed: () => setState(() => _showList = !_showList),
                ),
              ],
            ),
          ),
                  // List of places
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
                              child: place['image'].startsWith('http')
                                  ? Image.network(
                                      place['image'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.location_on,
                                        size: 40,
                                        color: Colors.red,
                                      ),
                                    ),
                            ),
                            title: Text(place['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            subtitle: Text(place['country']),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => _showPlaceDialog(place),
                              child: const Text("View on Map"),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Add Place Form (no lat/lng)
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
                            validator: (value) => value == null || value.isEmpty
                                ? "Enter place name"
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _countryController,
                            decoration: const InputDecoration(
                                labelText: "Country",
                                border: OutlineInputBorder()),
                            validator: (value) => value == null || value.isEmpty
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
