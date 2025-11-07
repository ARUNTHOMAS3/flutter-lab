// lib/firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'place_model.dart';

class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _collection =
      _firestore.collection('places');

  static Future<void> addPlace(Place place) async {
    await _collection.add({
      'name': place.name,
      'country': place.country,
      'image': place.image,
      'latitude': place.latLng.latitude,
      'longitude': place.latLng.longitude,
    });
  }

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

  static Future<void> updatePlace(DocumentReference docRef, Place place) async {
    await docRef.update({
      'name': place.name,
      'country': place.country,
      'image': place.image,
      'latitude': place.latLng.latitude,
      'longitude': place.latLng.longitude,
    });
  }

  static Future<List<Place>> getAllPlaces() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Place(
        name: data['name'] ?? '',
        country: data['country'] ?? '',
        image: data['image'] ?? '',
        latLng: LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        ),
      );
    }).toList();
  }

  /// ✅ NEW — Search by place name
  static Future<List<Place>> searchPlaces(String keyword) async {
    final query = await _collection
        .where("name", isEqualTo: keyword)
        .get();

    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Place(
        name: data['name'],
        country: data['country'],
        image: data['image'],
        latLng: LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        ),
      );
    }).toList();
  }
}
