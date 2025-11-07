// lib/firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'place_model.dart';

class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _collection =
      _firestore.collection('places');

  /// Adds a place (without returning the DocumentReference)
  static Future<void> addPlace(Place place) async {
    await _collection.add({
      'name': place.name,
      'country': place.country,
      'image': place.image,
      'latitude': place.latLng.latitude,
      'longitude': place.latLng.longitude,
    });
  }

  /// Adds a place and returns the DocumentReference (useful if you want to update later)
  static Future<DocumentReference> addPlaceAndGetRef(Place place) async {
    final ref = await _collection.add({
      'name': place.name,
      'country': place.country,
      'image': place.image,
      'latitude': place.latLng.latitude,
      'longitude': place.latLng.longitude,
    });
    return ref;
  }

  /// Update a place document using its DocumentReference
  static Future<void> updatePlace(DocumentReference docRef, Place place) async {
    await docRef.update({
      'name': place.name,
      'country': place.country,
      'image': place.image,
      'latitude': place.latLng.latitude,
      'longitude': place.latLng.longitude,
    });
  }

  /// Fetch all places from Firestore and convert to Place objects
  static Future<List<Place>> getAllPlaces() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // safely parse latitude/longitude
      double lat = 0.0;
      double lon = 0.0;
      if (data['latitude'] != null) {
        lat = (data['latitude'] is int)
            ? (data['latitude'] as int).toDouble()
            : (data['latitude'] as num).toDouble();
      }
      if (data['longitude'] != null) {
        lon = (data['longitude'] is int)
            ? (data['longitude'] as int).toDouble()
            : (data['longitude'] as num).toDouble();
      }

      return Place(
        name: data['name'] ?? '',
        country: data['country'] ?? '',
        image: data['image'] ?? '',
        latLng: LatLng(lat, lon),
      );
    }).toList();
  }

  /// Delete all documents in the collection (useful for cleaning SVG placeholders)
  static Future<void> deleteAllPlaces() async {
    final snapshot = await _collection.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
