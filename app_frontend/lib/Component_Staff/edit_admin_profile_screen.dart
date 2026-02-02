// ignore_for_file: depend_on_referenced_packages, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/translations.dart';
import 'package:path/path.dart' as path;

class EditAdminProfileScreen extends StatefulWidget {
  final String? adminId;
  final String? adminEmail;

  const EditAdminProfileScreen({super.key, this.adminId, this.adminEmail});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _profilePictureUrl;
  File? _newProfileImage;
  bool _isLoading = false;
  final String _currentLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.adminEmail ?? '';
    _fetchAdminProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminProfile() async {
    if (widget.adminId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/admin/profile/${widget.adminId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _nameController.text = data['admin']['name'] ?? '';
          _emailController.text = data['admin']['email'] ?? '';
          _profilePictureUrl = data['admin']['profilePicture'];
        } else {
          _showSnackBar(
            '${Translations.translate('failed_to_load_profile', _currentLanguage)}: ${data['message']}',
            Colors.red,
          );
        }
      } else {
        _showSnackBar(
          '${Translations.translate('failed_to_load_profile', _currentLanguage)}: ${json.decode(response.body)['message']}',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '${Translations.translate('server_error', _currentLanguage)}: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateAdminProfile() async {
    if (widget.adminId == null) return;

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("http://localhost:8000/api/admin/profile/${widget.adminId}"),
      );

      request.headers["Content-Type"] = "application/json";
      request.fields['email'] = _emailController.text.trim();
      request.fields['name'] = _nameController.text.trim();

      if (_newProfileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePicture',
            _newProfileImage!.path,
            filename: path.basename(_newProfileImage!.path),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar(
          Translations.translate(
            'profile_updated_successfully',
            _currentLanguage,
          ),
          Colors.green,
        );
        setState(() {
          _profilePictureUrl = data['admin']['profilePicture'];
          _newProfileImage = null; // Clear selected image
        });
      } else {
        _showSnackBar(
          data['message'] ??
              Translations.translate(
                'failed_to_update_profile',
                _currentLanguage,
              ),
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '${Translations.translate('server_error', _currentLanguage)}: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.translate('edit_profile', _currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.deepPurple.shade100,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!) as ImageProvider
                            : (_profilePictureUrl != null &&
                                      _profilePictureUrl!.isNotEmpty
                                  ? NetworkImage(
                                      "http://localhost:8000/" +
                                          _profilePictureUrl!,
                                    ) as ImageProvider
                                  : null),
                        child:
                            (_profilePictureUrl == null ||
                                    _profilePictureUrl!.isEmpty) &&
                                _newProfileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.deepPurple,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: Translations.translate('name', _currentLanguage),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: Translations.translate(
                      'email',
                      _currentLanguage,
                    ),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  readOnly: true, // Email is typically not editable once set
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateAdminProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          Translations.translate(
                            'update_profile',
                            _currentLanguage,
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
    );
  }
}
