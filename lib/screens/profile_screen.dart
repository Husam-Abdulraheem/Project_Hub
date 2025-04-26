import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_details_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDoc.snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data();
            return ListView(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage:
                          (data?['profilePic'] ?? '').isNotEmpty
                              ? NetworkImage(data!['profilePic'])
                              : null,
                      child:
                          (data?['profilePic'] ?? '').isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data?['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            user.email ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 18,
                              ),
                              Text(' ${data?['likes'] ?? 0} likes'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'My Projects',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('projects')
                          .where('ownerId', isEqualTo: user.uid)
                          .snapshots(),
                  builder: (context, snap) {
                    final projects = snap.data?.docs ?? [];
                    if (projects.isEmpty) return const Text('No projects yet.');
                    return Column(
                      children:
                          projects.map((doc) {
                            final p = doc.data();
                            return Card(
                              child: ListTile(
                                leading:
                                    (p['image'] ?? '').isNotEmpty
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            p['image'],
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : const Icon(Icons.image, size: 40),
                                title: Text(p['title'] ?? ''),
                                subtitle: Text('${p['likes'] ?? 0} likes'),
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ProjectDetailsScreen(
                                              projectId: doc.id,
                                            ),
                                      ),
                                    ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
