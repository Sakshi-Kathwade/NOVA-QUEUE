import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/translations.dart'; // Adjust path as needed

class ManageServicesScreen extends StatefulWidget {
  final String? adminId;
  final String? adminEmail;

  const ManageServicesScreen({super.key, this.adminId, this.adminEmail});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  List<dynamic> _services = [];
  bool _isLoading = true;
  final String _currentLanguage = 'english'; // Changed to final

  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _serviceDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    if (widget.adminId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/admin/settings/services/${widget.adminId}",
        ),
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return; // Add mounted check immediately after await

      final data = json.decode(response.body); // Moved data decoding here

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          setState(() {
            _services = data['services'];
          });
        }
      } else {
        _showSnackBar(
          '${Translations.translate('failed_to_load_services', _currentLanguage)}: ${data['message']}',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        // Only show snackbar if mounted
        _showSnackBar(
          '${Translations.translate('server_error', _currentLanguage)}: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addService() async {
    final serviceName = _serviceNameController.text.trim();
    final description = _serviceDescriptionController.text.trim();

    if (serviceName.isEmpty) {
      _showSnackBar(
        Translations.translate('service_name_required', _currentLanguage),
        Colors.red,
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          "http://localhost:8000/api/admin/settings/services/${widget.adminId}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "serviceName": serviceName,
          "description": description,
        }),
      );

      if (!mounted) return; // Add mounted check

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        _showSnackBar(
          Translations.translate(
            'service_added_successfully',
            _currentLanguage,
          ),
          Colors.green,
        );
        _serviceNameController.clear();
        _serviceDescriptionController.clear();
        Navigator.pop(context); // Close dialog
        _fetchServices(); // Refresh the list
      } else {
        _showSnackBar(
          data['message'] ??
              Translations.translate('failed_to_add_service', _currentLanguage),
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return; // Add mounted check
      _showSnackBar(
        '${Translations.translate('server_error', _currentLanguage)}: $e',
        Colors.red,
      );
    }
  }

  Future<void> _updateService(String serviceId) async {
    final serviceName = _serviceNameController.text.trim();
    final description = _serviceDescriptionController.text.trim();

    if (serviceName.isEmpty) {
      _showSnackBar(
        Translations.translate('service_name_required', _currentLanguage),
        Colors.red,
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
          "http://localhost:8000/api/admin/settings/services/$serviceId/${widget.adminId}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "serviceName": serviceName,
          "description": description,
        }),
      );

      if (!mounted) return; // Add mounted check

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar(
          Translations.translate(
            'service_updated_successfully',
            _currentLanguage,
          ),
          Colors.green,
        );
        _serviceNameController.clear();
        _serviceDescriptionController.clear();
        Navigator.pop(context); // Close dialog
        _fetchServices(); // Refresh the list
      } else {
        _showSnackBar(
          data['message'] ??
              Translations.translate(
                'failed_to_update_service',
                _currentLanguage,
              ),
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return; // Add mounted check
      _showSnackBar(
        '${Translations.translate('server_error', _currentLanguage)}: $e',
        Colors.red,
      );
    }
  }

  Future<void> _deleteService(String serviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('confirm_delete', _currentLanguage)),
        content: Text(
          Translations.translate(
            'delete_service_confirmation',
            _currentLanguage,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.translate('cancel', _currentLanguage)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              Translations.translate('delete', _currentLanguage),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return; // Add mounted check
    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse(
            "http://localhost:8000/api/admin/settings/services/$serviceId/${widget.adminId}",
          ),
          headers: {"Content-Type": "application/json"},
        );

        if (!mounted) return; // Add mounted check

        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          _showSnackBar(
            Translations.translate(
              'service_deleted_successfully',
              _currentLanguage,
            ),
            Colors.green,
          );
          _fetchServices(); // Refresh the list
        } else {
          _showSnackBar(
            data['message'] ??
                Translations.translate(
                  'failed_to_delete_service',
                  _currentLanguage,
                ),
            Colors.red,
          );
        }
      } catch (e) {
        if (!mounted) return; // Add mounted check
        _showSnackBar(
          '${Translations.translate('server_error', _currentLanguage)}: $e',
          Colors.red,
        );
      }
    }
  }

  void _showAddEditServiceDialog({Map<String, dynamic>? service}) {
    bool isEditing = service != null;
    if (isEditing) {
      _serviceNameController.text = service['serviceName'];
      _serviceDescriptionController.text = service['description'] ?? '';
    } else {
      _serviceNameController.clear();
      _serviceDescriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing
              ? Translations.translate('edit_service', _currentLanguage)
              : Translations.translate('add_service', _currentLanguage),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _serviceNameController,
              decoration: InputDecoration(
                labelText: Translations.translate(
                  'service_name',
                  _currentLanguage,
                ),
              ),
            ),
            TextField(
              controller: _serviceDescriptionController,
              decoration: InputDecoration(
                labelText: Translations.translate(
                  'description',
                  _currentLanguage,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _serviceNameController.clear();
              _serviceDescriptionController.clear();
            },
            child: Text(Translations.translate('cancel', _currentLanguage)),
          ),
          ElevatedButton(
            onPressed: () {
              if (isEditing) {
                _updateService(service['_id']);
              } else {
                _addService();
              }
            },
            child: Text(
              isEditing
                  ? Translations.translate('update', _currentLanguage)
                  : Translations.translate('add', _currentLanguage),
            ),
          ),
        ],
      ),
    );
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
        title: Text(
          Translations.translate('manage_services', _currentLanguage),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Text(
                    Translations.translate('no_services_yet', _currentLanguage),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          service['serviceName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          service['description'] ??
                              Translations.translate(
                                'no_description',
                                _currentLanguage,
                              ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showAddEditServiceDialog(service: service),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteService(service['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditServiceDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
