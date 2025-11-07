// lib/place_model.dart
import 'package:latlong2/latlong.dart';

class Place {
  final String name;
  final String country;
  final String image;
  final LatLng latLng;

  Place({
    required this.name,
    required this.country,
    required this.image,
    required this.latLng,
  });
}
