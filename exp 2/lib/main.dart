import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  // Famous places with image, name, location
  final List<Map<String, dynamic>> places = [
    {
      'name': 'Taj Mahal',
      'country': 'India',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/d/da/Taj-Mahal.jpg',
      'latLng': LatLng(27.1751, 78.0421),
    },
    {
      'name': 'Eiffel Tower',
      'country': 'France',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/a/a8/Tour_Eiffel_Wikimedia_Commons.jpg',
      'latLng': LatLng(48.8584, 2.2945),
    },
    {
      'name': 'Statue of Liberty',
      'country': 'USA',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/a/a1/Statue_of_Liberty_7.jpg',
      'latLng': LatLng(40.6892, -74.0445),
    },
    {
      'name': 'Great Wall',
      'country': 'China',
      'image': 'data:image/jpeg;base64,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',
      'latLng': LatLng(40.4319, 116.5704),
    },
    {
      'name': 'Sydney Opera House',
      'country': 'Australia',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/4/40/Sydney_Opera_House_Sails.jpg',
      'latLng': LatLng(-33.8568, 151.2153),
    },
  ];

  void _viewOnMap(Map<String, dynamic> place) {
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
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(20.5937, 78.9629), // India center
                initialZoom: 2,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),

          // Famous Places List
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        place['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(place['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(place['country']),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _viewOnMap(place),
                      child: const Text("View on Map"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 