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
  String? _title, _description, _category, _url, _orgName, _githubRepo, _imageUrl;
  bool _loading = false;
  final _categories = ['Technical', 'Educational', 'Creative', 'Business', 'Health', 'Science', 'Art', 'Other'];

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
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: data['title'],
                        decoration: const InputDecoration(labelText: 'Title'),
                        onSaved: (v) => _title = v,
                        validator:
                            (v) =>
                                v == null || v.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: data['description'],
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        onSaved: (v) => _description = v,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter a description'
                                    : null,
                      ),
                      const SizedBox(height: 12),
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
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator:
                            (v) => v == null ? 'Select a category' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: data['url'],
                        decoration: const InputDecoration(
                          labelText: 'URL (optional)',
                        ),
                        onSaved: (v) => _url = v,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: data['orgName'],
                        decoration: const InputDecoration(
                          labelText: 'Organization Name',
                        ),
                        onSaved: (v) => _orgName = v,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter organization name'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: data['githubRepo'],
                        decoration: const InputDecoration(
                          labelText: 'GitHub Repo Link',
                        ),
                        onSaved: (v) => _githubRepo = v,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: data['image'],
                        decoration: const InputDecoration(
                          labelText: 'Project Image URL (optional)',
                        ),
                        onSaved: (v) => _imageUrl = v,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && !Uri.parse(v).isAbsolute) {
                            return 'Enter a valid image URL or leave blank';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              );
        },
      ),
    );
  }
}
