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
  bool _showList = true;
  String _searchQuery = '';


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
    {
      'name': 'Great Wall',
      'country': 'China',
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR628asBrRG1fu2yG0YR0QErqKIZ2tbc2s_Cw&s',
      'latLng': LatLng(40.4319, 116.5704),
    },
    {
      'name': 'Sydney Opera House',
      'country': 'Australia',
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/4/40/Sydney_Opera_House_Sails.jpg',
      'latLng': LatLng(-33.8568, 151.2153),
    },
  ];

  // Function to move map
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

  // Function to show dialog
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
              child: Image.network(place['image'], height: 150, fit: BoxFit.cover),
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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          final newZoom = (_mapController.camera.zoom + 1).clamp(1.0, 18.0);
                          _mapController.move(_mapController.camera.center, newZoom);
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: () {
                          final newZoom = (_mapController.camera.zoom - 1).clamp(1.0, 18.0);
                          _mapController.move(_mapController.camera.center, newZoom);
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
                if (!_showList)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton.small(
                        onPressed: () => setState(() => _showList = true),
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Famous Places List
          if (_showList)
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Famous Places', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_up),
                          onPressed: () => setState(() => _showList = false),
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
                              onPressed: () => _showPlaceDialog(place),
                              child: const Text("View on Map"),
                            ),
                          ),
                        );
                      },
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
