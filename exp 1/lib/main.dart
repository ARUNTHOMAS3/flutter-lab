import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Permission.location.request();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Location Picker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapPickerScreen(),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedLocation;
  String? _address;
  bool _isLoading = false;
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _favorites = []; // For saved locations
  bool _mapInitialized = false;

  final LatLng _initialPosition = LatLng(20.5937, 78.9629); // Center of India
  final double _initialZoom = 5.0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _checkLocationPermission();
    setState(() => _mapInitialized = true);
  }

  Future<void> _checkLocationPermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        await _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not supported on this platform')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      _mapController.move(latLng, 15);
      _updateSelectedLocation(latLng);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        _mapController.move(latLng, 15);
        _updateSelectedLocation(latLng);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSelectedLocation(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _markers = [
        Marker(
          point: latLng,
          width: 80,
          height: 80,
          builder: (ctx) => const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      ];
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      }
    } catch (_) {
      setState(() => _address = null);
    }
  }

  Widget _buildMap() {
    if (!_mapInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _initialPosition,
        zoom: _initialZoom,
        onTap: (tapPosition, latLng) => _updateSelectedLocation(latLng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  void _saveToFavorites() {
    if (_selectedLocation != null && _address != null) {
      setState(() {
        _favorites.add({
          'location': _selectedLocation,
          'address': _address,
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Favorites')),
      );
    }
  }

  void _showFavorites() {
    if (_favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No favorites saved yet')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final fav = _favorites[index];
          final loc = fav['location'] as LatLng;
          return ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(fav['address']),
            subtitle: Text(
              '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
            ),
            onTap: () {
              Navigator.pop(context);
              _mapController.move(loc, 15);
              _updateSelectedLocation(loc);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Location Picker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _showFavorites,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),

          // Location Info Card
          if (_selectedLocation != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_address != null) ...[
                        Text("📍 Address:", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(_address!),
                        const Divider(),
                      ],
                      Text("🌐 Coordinates:", style: Theme.of(context).textTheme.titleMedium),
                      Text('${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text("Copy"),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: '$_address\n${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied to clipboard')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.star),
                              label: const Text("Save"),
                              onPressed: _saveToFavorites,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),

      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: "zoomIn",
            onPressed: () => _mapController.move(_mapController.center, _mapController.zoom + 1),
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "zoomOut",
            onPressed: () => _mapController.move(_mapController.center, _mapController.zoom - 1),
            child: const Icon(Icons.zoom_out),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "myLocation",
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
