import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projecthub/screens/edit_project_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({Key? key, required this.projectId})
    : super(key: key);

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool _liking = false;

  Future<void> _likeProject(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_liking) return;
    setState(() => _liking = true);
    final doc = snapshot.reference;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like.')),
      );
      setState(() => _liking = false);
      return;
    }
    final data = snapshot.data();
    final List likesList = data?['likesList'] ?? [];
    final int currentLikes = data?['likes'] ?? 0;
    bool hasLiked = likesList.contains(user.uid);
    try {
      if (hasLiked) {
        await doc.update({
          'likesList': FieldValue.arrayRemove([user.uid]),
          'likes': currentLikes > 0 ? currentLikes - 1 : 0,
        });
      } else {
        await doc.update({
          'likesList': FieldValue.arrayUnion([user.uid]),
          'likes': currentLikes + 1,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: ${e.toString()}')),
      );
    }
    setState(() => _liking = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final project = snapshot.data?.data();
          if (project == null)
            return const Center(child: Text('Project not found.'));
          final likesList = project['likesList'] ?? [];
          final hasLiked = user != null && likesList.contains(user.uid);
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.all(16),
            child: ListView(
              children: [
                if ((project['image'] ?? '').isNotEmpty)
                  Image.network(
                    project['image'],
                    height: 180,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 60),
                  ),
                const SizedBox(height: 16),
                Text(
                  project['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(project['description'] ?? ''),
                const SizedBox(height: 8),
                if ((project['orgName'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Organization: ${project['orgName']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if ((project['githubRepo'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        final url = project['githubRepo'];
                        if (url != null && url.isNotEmpty) {
                          launchUrl(Uri.parse(url));
                        }
                      },
                      child: Text(
                        project['githubRepo'],
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        hasLiked ? Icons.favorite : Icons.favorite_border,
                        color: hasLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed:
                          user == null
                              ? null
                              : () => _likeProject(snapshot.data!),
                    ),
                    Text('${project['likes'] ?? 0} likes'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        final ownerId = project['ownerId'];
                        if (ownerId != null) {
                          final userDoc =
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(ownerId)
                                  .get();
                          final ownerEmail =
                              userDoc.data()?['email'] ?? 'No email found';
                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(content: Text(ownerEmail)),
                          );
                        }
                      },
                      child: const Text('Contact Owner'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (user != null && user.uid == project['ownerId'])
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EditProjectScreen(
                                    projectId: widget.projectId,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Project'),
                                  content: const Text(
                                    'Are you sure you want to delete this project?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('projects')
                                .doc(widget.projectId)
                                .delete();
                            if (mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
