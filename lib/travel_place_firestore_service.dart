import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravelPlaceFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('กรุณาเข้าสู่ระบบก่อนใช้งาน');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _places {
    return _firestore.collection('travel_places');
  }

  // อ่านเฉพาะสถานที่ท่องเที่ยวของผู้ใช้ที่เข้าสู่ระบบ
  Stream<List<Map<String, dynamic>>> watchPlaces() {
    final userId = _userId;

    return _places
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'firestoreId': doc.id,
        };
      }).toList();
    });
  }

  // เพิ่มสถานที่ท่องเที่ยวและ userId
  Future<String> addPlace(Map<String, dynamic> data) async {
    final userId = _userId;

    final docRef = await _places.add({
      ...data,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // แก้ไขข้อมูล โดยตรวจสอบเจ้าของเอกสาร
  Future<void> updatePlace(
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final userId = _userId;
    final doc = _places.doc(documentId);
    final snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
      throw StateError('ไม่มีสิทธิ์แก้ไขข้อมูลนี้');
    }

    await doc.update(data);
  }

  // ลบข้อมูล โดยตรวจสอบเจ้าของเอกสาร
  Future<void> deletePlace(String documentId) async {
    final userId = _userId;
    final doc = _places.doc(documentId);
    final snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
      throw StateError('ไม่มีสิทธิ์ลบข้อมูลนี้');
    }

    await doc.delete();
  }

  
  Future<void> toggleFavorite(String documentId, bool isFavorite) async {
    final userId = _userId;
    final doc = _places.doc(documentId);
    final snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
      throw StateError('ไม่มีสิทธิ์แก้ไขข้อมูลนี้');
    }

    await doc.update({
      'isFavorite': isFavorite,
    });
  }
}