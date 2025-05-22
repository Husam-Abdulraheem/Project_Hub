import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projecthub/screens/edit_project_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projecthub/main.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({Key? key, required this.projectId})
    : super(key: key);

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool _liking = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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

  Future<void> _addComment(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || text.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('comments')
        .add({
          'text': text.trim(),
          'userId': user.uid,
          'userEmail': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
    _commentController.clear();
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
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: (project['image'] ?? '').isNotEmpty
                            ? Image.network(
                                project['image'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 60),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Title & Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              project['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if ((project['category'] ?? '').isNotEmpty)
                            Chip(
                              label: Text(project['category']),
                              backgroundColor: kSecondary.withOpacity(0.15),
                              labelStyle: TextStyle(color: kSecondary, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Owner Info
                      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(project['ownerId'])
                            .get(),
                        builder: (context, ownerSnap) {
                          final owner = ownerSnap.data?.data();
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: (owner?['profilePic'] ?? '').isNotEmpty
                                    ? NetworkImage(owner!['profilePic'])
                                    : null,
                                child: (owner?['profilePic'] ?? '').isEmpty
                                    ? const Icon(Icons.person, size: 18)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  Text(
                                owner?['name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                owner?['email'] ?? '',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Info Rows
                      if ((project['description'] ?? '').isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description, color: kPrimary),
                          title: Text(project['description']),
                        ),
                      if ((project['orgName'] ?? '').isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.business, color: kPrimary),
                          title: Text('Organization: ${project['orgName']}'),
                        ),
                      if ((project['githubRepo'] ?? '').isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.code, color: kPrimary),
                          title: InkWell(
                            onTap: () {
                              final url = project['githubRepo'];
                              if (url != null && url.isNotEmpty) {
                                launchUrl(Uri.parse(url));
                              }
                            },
                            child: Text(
                              project['githubRepo'],
                              style: const TextStyle(
                                color: kSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Likes
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              hasLiked ? Icons.favorite : Icons.favorite_border,
                              color: hasLiked ? Colors.red : Colors.grey,
                              size: 28,
                            ),
                            onPressed: user == null ? null : () => _likeProject(snapshot.data!),
                          ),
                          Text(
                            '${project['likes'] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 3),
                          const Text('likes', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          if (user != null && user.uid == project['ownerId'])
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProjectScreen(
                                          projectId: widget.projectId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 5),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Project'),
                                        content: const Text('Are you sure you want to delete this project?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                      const Divider(height: 32),
                      // Comments Section
                      Row(
                        children: const [
                          Icon(Icons.comment, color: kPrimary),
                          SizedBox(width: 8),
                          Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('projects')
                            .doc(widget.projectId)
                            .collection('comments')
                            .orderBy('createdAt', descending: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final comments = snapshot.data?.docs ?? [];
                          if (comments.isEmpty) {
                            return const Text('No comments yet. Be the first to comment!');
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final c = comments[index].data();
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: kSecondary.withOpacity(0.2),
                                    child: const Icon(Icons.person, size: 16, color: kSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: kThird,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c['userEmail'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            c['text'] ?? '',
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              c['createdAt'] != null
                                                  ? (c['createdAt'] as Timestamp)
                                                      .toDate()
                                                      .toLocal()
                                                      .toString()
                                                      .substring(0, 16)
                                                  : '',
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (user != null)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Write a comment...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: kSecondary),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(12),
                                backgroundColor: kPrimary,
                              ),
                              onPressed: () => _addComment(_commentController.text),
                              child: const Icon(Icons.send, color: Colors.white),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
