// lib/firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_model.dart';

class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _collection =
      _firestore.collection('places');

  /// Add new place and return document reference
  static Future<DocumentReference> addPlaceAndGetRef(Place place) async {
    return await _collection.add(place.toMap());
  }

  /// Add new place (no ref)
  static Future<void> addPlace(Place place) async {
    await _collection.add(place.toMap());
  }

  /// Update place (requires place.id)
  static Future<void> updatePlace(Place place) async {
    if (place.id.isEmpty) {
      throw ArgumentError("Place.id is required for update!");
    }
    await _collection.doc(place.id).update(place.toMap());
  }

  /// Delete place by doc id
  static Future<void> deletePlace(String id) async {
    await _collection.doc(id).delete();
  }

  /// Fetch all places (reads docID)
  static Future<List<Place>> getPlaces() async {
    final snapshot = await _collection.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Place.fromFirestore(doc.id, data);
    }).toList();
  }

  /// Backwards-compatible alias used by older UI code
  static Future<List<Place>> getAllPlaces() => getPlaces();

  /// SEARCH — partial case-insensitive on name
  static Future<List<Place>> searchPlaces(String keyword) async {
    keyword = keyword.toLowerCase();

    final snapshot = await _collection.get();
    List<Place> results = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String name = (data['name'] ?? "").toString().toLowerCase();

      if (name.contains(keyword)) {
        results.add(
          Place.fromFirestore(doc.id, data),
        );
      }
    }

    return results;
  }
}
