import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  XFile? _pickedImage;
  bool _loading = false;

  final List<String> _categories = ['Technical', 'Educational', 'Creative'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<String?> _uploadImage(String projectId) async {
    if (_pickedImage == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('project_images')
        .child('$projectId.jpg');
    await ref.putData(await _pickedImage!.readAsBytes());
    return await ref.getDownloadURL();
  }

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
    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadImage(docRef.id);
    }
    await docRef.set({
      'title': _title,
      'description': _description,
      'category': _category,
      'image': imageUrl ?? '',
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
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child:
                                _pickedImage != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        File(_pickedImage!.path),
                                        height: 140,
                                        width: 140,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Container(
                                      height: 140,
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey[400]!,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: Colors.brown,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Project Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          onSaved: (val) => _title = val,
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Enter a title'
                                      : null,
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
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Enter a description'
                                      : null,
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
                          items:
                              _categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) => setState(() => _category = val),
                          validator:
                              (val) => val == null ? 'Select a category' : null,
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
                            if (val != null &&
                                val.isNotEmpty &&
                                Uri.tryParse(val)?.isAbsolute != true) {
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
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Enter organization name'
                                      : null,
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
                        const SizedBox(height: 16),
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
                            ),
                            onPressed: _submit,
                            label: const Text(
                              'Submit Project',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
