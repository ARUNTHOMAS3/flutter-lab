// lib/place_model.dart
import 'package:latlong2/latlong.dart';

class Place {
  final String id;
  final String name;
  final String country;
  final String image;
  final LatLng latLng;

  Place({
    this.id = "",
    required this.name,
    required this.country,
    required this.image,
    required this.latLng,
  });

  factory Place.fromFirestore(String id, Map<String, dynamic> data) {
    return Place(
      id: id,
      name: data["name"] ?? "",
      country: data["country"] ?? "",
      image: data["image"] ?? "",
      latLng: LatLng(
        (data["latitude"] as num).toDouble(),
        (data["longitude"] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "country": country,
      "image": image,
      "latitude": latLng.latitude,
      "longitude": latLng.longitude,
    };
  }
}
