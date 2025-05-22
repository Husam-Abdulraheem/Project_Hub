import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProjectScreen extends StatefulWidget {
  final String projectId;
  const EditProjectScreen({Key? key, required this.projectId})
    : super(key: key);
  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title,
      _description,
      _category,
      _url,
      _orgName,
      _githubRepo,
      _imageUrl;
  bool _loading = false;
  final _categories = [
    'Technical',
    'Educational',
    'Creative',
    'Business',
    'Health',
    'Science',
    'Art',
    'Other',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .update({
          'title': _title,
          'description': _description,
          'category': _category,
          'url': _url ?? '',
          'orgName': _orgName ?? '',
          'githubRepo': _githubRepo ?? '',
          'image': _imageUrl ?? '',
        });
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Project')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data();
          if (data == null)
            return const Center(child: Text('Project not found.'));
          return _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Project',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            initialValue: data['title'],
                            decoration: InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.title),
                            ),
                            onSaved: (v) => _title = v,
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Enter a title'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: data['description'],
                            decoration: InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 4,
                            onSaved: (v) => _description = v,
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Enter a description'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: data['category'],
                            items:
                                _categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => _category = v,
                            onSaved: (v) => _category = v,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.category),
                            ),
                            validator:
                                (v) => v == null ? 'Select a category' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: data['image'],
                            decoration: InputDecoration(
                              labelText: 'Project Image URL (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.image),
                            ),
                            onSaved: (v) => _imageUrl = v,
                            validator: (v) {
                              if (v != null &&
                                  v.isNotEmpty &&
                                  !Uri.parse(v).isAbsolute) {
                                return 'Enter a valid image URL or leave blank';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: data['url'],
                            decoration: InputDecoration(
                              labelText: 'URL (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.link),
                            ),
                            onSaved: (v) => _url = v,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: data['orgName'],
                            decoration: InputDecoration(
                              labelText: 'Organization Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.business),
                            ),
                            onSaved: (v) => _orgName = v,
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Enter organization name'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: data['githubRepo'],
                            decoration: InputDecoration(
                              labelText: 'GitHub Repo Link',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.link),
                            ),
                            onSaved: (v) => _githubRepo = v,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _submit,
                              label: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
        },
      ),
      bottomNavigationBar: null,
    );
  }
}
