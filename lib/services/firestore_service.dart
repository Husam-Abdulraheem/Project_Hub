import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Add a new project
  Future<void> addProject(Map<String, dynamic> data) async {
    await _db.collection('projects').add(data);
  }

  // Get all projects (stream for real-time updates)
  Stream<QuerySnapshot<Map<String, dynamic>>> getProjects() {
    return _db
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update a project by document ID
  Future<void> updateProject(String docId, Map<String, dynamic> data) async {
    await _db.collection('projects').doc(docId).update(data);
  }

  // Delete a project by document ID
  Future<void> deleteProject(String docId) async {
    await _db.collection('projects').doc(docId).delete();
  }
}
