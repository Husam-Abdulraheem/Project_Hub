import 'package:flutter/material.dart';

class AboutDevelopersScreen extends StatelessWidget {
  const AboutDevelopersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final developers = [
      {'name': 'Husam Abdulraheem', 'role': 'Flutter Developer'},
      {'name': 'Emad Aldeen Hasan', 'role': 'UI/UX Designer'},
      {'name': 'Ali Alahdal', 'role': 'Backend Engineer'},
      {'name': 'Abshir Hasan', 'role': 'UI/UX Designer'},
      {'name': 'Edris', 'role': 'Flutter Developer'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('About the Developers')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Meet the Team',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF583101),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This app was crafted with passion and teamwork by:',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: developers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder:
                    (context, i) => Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF8B5E34),
                              child: Text(
                                developers[i]['name']![0],
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  developers[i]['name']!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  developers[i]['role']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '© 2025 ProjectHub Team',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
