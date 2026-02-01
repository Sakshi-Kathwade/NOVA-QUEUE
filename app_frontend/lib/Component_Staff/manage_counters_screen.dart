import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/translations.dart';

class ManageCountersScreen extends StatefulWidget {
  final String? adminId;
  final String? adminEmail;

  const ManageCountersScreen({super.key, this.adminId, this.adminEmail});

  @override
  State<ManageCountersScreen> createState() => _ManageCountersScreenState();
}

class _ManageCountersScreenState extends State<ManageCountersScreen> {
  List<dynamic> _counters = [];
  bool _isLoading = true;
  final String _currentLanguage = 'english';

  final TextEditingController _counterNameController = TextEditingController();
  // For assigning staff, you might need a dropdown with staff data
  // For simplicity, this example won't include staff assignment in the dialog yet.

  @override
  void initState() {
    super.initState();
    _fetchCounters();
  }

  @override
  void dispose() {
    _counterNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchCounters() async {
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
        Uri.parse("http://localhost:8000/api/admin/settings/counters/${widget.adminId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _counters = data['counters'];
          });
        } else {
          _showSnackBar('${Translations.translate('failed_to_load_counters', _currentLanguage)}: ${data['message']}', Colors.red);
        }
      } else {
        _showSnackBar('${Translations.translate('failed_to_load_counters', _currentLanguage)}: ${json.decode(response.body)['message']}', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${Translations.translate('server_error', _currentLanguage)}: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addCounter() async {
    final counterName = _counterNameController.text.trim();

    if (counterName.isEmpty) {
      _showSnackBar(Translations.translate('counter_name_required', _currentLanguage), Colors.red);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/api/admin/settings/counters/${widget.adminId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"counterName": counterName}),
      );

      if (!mounted) return;

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        _showSnackBar(Translations.translate('counter_added_successfully', _currentLanguage), Colors.green);
        _counterNameController.clear();
        Navigator.pop(context); // Close dialog
        _fetchCounters(); // Refresh the list
      } else {
        _showSnackBar(data['message'] ?? Translations.translate('failed_to_add_counter', _currentLanguage), Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('${Translations.translate('server_error', _currentLanguage)}: $e', Colors.red);
    }
  }

  Future<void> _updateCounter(String counterId) async {
    final counterName = _counterNameController.text.trim();

    if (counterName.isEmpty) {
      _showSnackBar(Translations.translate('counter_name_required', _currentLanguage), Colors.red);
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/admin/settings/counters/$counterId/${widget.adminId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"counterName": counterName}),
      );

      if (!mounted) return;

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar(Translations.translate('counter_updated_successfully', _currentLanguage), Colors.green);
        _counterNameController.clear();
        Navigator.pop(context); // Close dialog
        _fetchCounters(); // Refresh the list
      } else {
        _showSnackBar(data['message'] ?? Translations.translate('failed_to_update_counter', _currentLanguage), Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('${Translations.translate('server_error', _currentLanguage)}: $e', Colors.red);
    }
  }

  Future<void> _deleteCounter(String counterId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate('confirm_delete', _currentLanguage)),
        content: Text(Translations.translate('delete_counter_confirmation', _currentLanguage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Translations.translate('cancel', _currentLanguage)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(Translations.translate('delete', _currentLanguage), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse("http://localhost:8000/api/admin/settings/counters/$counterId/${widget.adminId}"),
          headers: {"Content-Type": "application/json"},
        );

        if (!mounted) return;

        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          _showSnackBar(Translations.translate('counter_deleted_successfully', _currentLanguage), Colors.green);
          _fetchCounters(); // Refresh the list
        } else {
          _showSnackBar(data['message'] ?? Translations.translate('failed_to_delete_counter', _currentLanguage), Colors.red);
        }
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('${Translations.translate('server_error', _currentLanguage)}: $e', Colors.red);
      }
    }
  }

  void _showAddEditCounterDialog({Map<String, dynamic>? counter}) {
    bool isEditing = counter != null;
    if (isEditing) {
      _counterNameController.text = counter['counterName'];
    } else {
      _counterNameController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing
            ? Translations.translate('edit_counter', _currentLanguage)
            : Translations.translate('add_counter', _currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _counterNameController,
              decoration: InputDecoration(
                labelText: Translations.translate('counter_name', _currentLanguage),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _counterNameController.clear();
            },
            child: Text(Translations.translate('cancel', _currentLanguage)),
          ),
          ElevatedButton(
            onPressed: () {
              if (isEditing) {
                _updateCounter(counter['_id']);
              } else {
                _addCounter();
              }
            },
            child: Text(isEditing
                ? Translations.translate('update', _currentLanguage)
                : Translations.translate('add', _currentLanguage)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.translate('manage_counters', _currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _counters.isEmpty
              ? Center(
                  child: Text(
                    Translations.translate('no_counters_yet', _currentLanguage),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _counters.length,
                  itemBuilder: (context, index) {
                    final counter = _counters[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          counter['counterName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(counter['status'] ?? Translations.translate('status_unavailable', _currentLanguage)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditCounterDialog(counter: counter),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCounter(counter['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCounterDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
