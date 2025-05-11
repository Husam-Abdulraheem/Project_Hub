import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({Key? key}) : super(key: key);

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  String? _category;
  String? _url;
  String? _orgName;
  String? _githubRepo;
  String? _imageUrl;
  bool _loading = false;

  final List<String> _categories = ['Technical', 'Educational', 'Creative', 'Business', 'Health', 'Science', 'Art', 'Other'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _loading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      setState(() {
        _loading = false;
      });
      return;
    }
    final docRef = FirebaseFirestore.instance.collection('projects').doc();
    String? imageUrlToSave = _imageUrl;
    if (imageUrlToSave == null || imageUrlToSave.isEmpty) {
      // Placeholder for the removed _uploadImage method
    }
    await docRef.set({
      'title': _title,
      'description': _description,
      'category': _category,
      'image': imageUrlToSave ?? '',
      'url': _url ?? '',
      'orgName': _orgName ?? '',
      'githubRepo': _githubRepo ?? '',
      'ownerId': user.uid,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _loading = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Project added!')));
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Project')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Project',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Image URL preview
                            if (_imageUrl != null && _imageUrl!.isNotEmpty && Uri.tryParse(_imageUrl!)?.isAbsolute == true)
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _imageUrl!,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Project Title',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.title),
                              ),
                              onSaved: (val) => _title = val,
                              validator: (val) => val == null || val.isEmpty ? 'Enter a title' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.description),
                              ),
                              maxLines: 4,
                              onSaved: (val) => _description = val,
                              validator: (val) => val == null || val.isEmpty ? 'Enter a description' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.category),
                              ),
                              items: _categories
                                  .map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _category = val),
                              validator: (val) => val == null ? 'Select a category' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Project Image URL (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.image),
                              ),
                              onChanged: (val) => setState(() => _imageUrl = val),
                              onSaved: (val) => _imageUrl = val,
                              validator: (val) {
                                if (val != null && val.isNotEmpty && !Uri.parse(val).isAbsolute) {
                                  return 'Enter a valid image URL or leave blank';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Project URL (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.link),
                              ),
                              onSaved: (val) => _url = val,
                              validator: (val) {
                                if (val != null && val.isNotEmpty && Uri.tryParse(val)?.isAbsolute != true) {
                                  return 'Enter a valid URL or leave blank';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Organization Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.business),
                              ),
                              onSaved: (val) => _orgName = val,
                              validator: (val) => val == null || val.isEmpty ? 'Enter organization name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'GitHub Repo Link',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.link),
                              ),
                              onSaved: (val) => _githubRepo = val,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.cloud_upload),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _submit,
                                label: const Text('Submit Project'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
