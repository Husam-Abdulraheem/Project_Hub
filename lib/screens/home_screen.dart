import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecthub/main.dart';
import 'project_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> categories = [
    'All',
    'Technical',
    'Educational',
    'Creative',
    'Business',
    'Health',
    'Science',
    'Art',
    'Other',
  ];
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ProjectHub')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ChoiceChip(
                          label: Text(categories[index]),
                          selected: selectedCategory == categories[index],
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = categories[index];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Featured Projects Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Featured Projects',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            selectedCategory == 'All'
                                ? FirebaseFirestore.instance
                                    .collection('projects')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots()
                                : FirebaseFirestore.instance
                                    .collection('projects')
                                    .where(
                                      'category',
                                      isGreaterThanOrEqualTo: selectedCategory,
                                    )
                                    .where(
                                      'category',
                                      isLessThanOrEqualTo:
                                          selectedCategory + '\uf8ff',
                                    )
                                    .orderBy('category')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final projects = snapshot.data?.docs ?? [];
                          if (projects.isEmpty) {
                            return const Center(
                              child: Text('No projects found.'),
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: projects.length,
                            itemBuilder: (context, index) {
                              final project = projects[index].data();
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ProjectDetailsScreen(
                                              projectId: projects[index].id,
                                            ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: kThird,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child:
                                                project['image'] != null &&
                                                        project['image'] != ''
                                                    ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        project['image'],
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                      ),
                                                    )
                                                    : const Icon(
                                                      Icons.image,
                                                      size: 48,
                                                      color: Colors.white70,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          project['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          project['category'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              project['likes'] != 0 ? Icons.favorite : Icons.favorite_border,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text('${project['likes'] ?? 0}'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Most Liked Projects Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Most Liked Projects',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('projects')
                                .orderBy('likes', descending: true)
                                .limit(5)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final projects = snapshot.data?.docs ?? [];
                          if (projects.isEmpty) {
                            return const Center(
                              child: Text('No liked projects found.'),
                            );
                          }
                          return SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              itemCount: projects.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final project = projects[index].data();
                                return SizedBox(
                                  width: 160,
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    ProjectDetailsScreen(
                                                      projectId:
                                                          projects[index].id,
                                                    ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: kThird,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child:
                                                    project['image'] != null &&
                                                            project['image'] !=
                                                                ''
                                                        ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.network(
                                                            project['image'],
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                          ),
                                                        )
                                                        : const Icon(
                                                          Icons.image,
                                                          size: 48,
                                                          color: Colors.white70,
                                                        ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              project['title'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              project['category'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.favorite,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${project['likes'] ?? 0}',
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
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Projects You Liked Section
              Builder(
                builder: (context) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    return const SizedBox();
                  }
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Projects You Liked',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('projects')
                                    .where('likesList', arrayContains: user.uid)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final projects = snapshot.data?.docs ?? [];
                              if (projects.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'You have not liked any projects yet.',
                                  ),
                                );
                              }
                              return SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                  ),
                                  itemCount: projects.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final project = projects[index].data();
                                    return SizedBox(
                                      width: 160,
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        ProjectDetailsScreen(
                                                          projectId:
                                                              projects[index]
                                                                  .id,
                                                        ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: kThird,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child:
                                                        project['image'] !=
                                                                    null &&
                                                                project['image'] !=
                                                                    ''
                                                            ? ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              child: Image.network(
                                                                project['image'],
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                                width:
                                                                    double
                                                                        .infinity,
                                                              ),
                                                            )
                                                            : const Icon(
                                                              Icons.image,
                                                              size: 48,
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                            ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  project['title'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  project['category'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.favorite,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${project['likes'] ?? 0}',
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
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
