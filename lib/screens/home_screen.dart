import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecthub/main.dart';
import 'project_details_screen.dart';
import 'about_developers_screen.dart';

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
  ];
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProjectHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Developers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AboutDevelopersScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Featured Projects',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                            isLessThanOrEqualTo: selectedCategory + '\uf8ff',
                          )
                          .orderBy('category')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final projects = snapshot.data?.docs ?? [];
                if (projects.isEmpty) {
                  return const Center(child: Text('No projects found.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: kThird,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      project['image'] != null &&
                                              project['image'] != ''
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
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
                                  const Icon(
                                    Icons.favorite,
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
          ),
        ],
      ),
    );
  }
}
