// ignore_for_file: use_super_parameters, library_private_types_in_public_api, use_build_context_synchronously, empty_catches

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/api_config.dart'; // ✅ Import ApiConfig
import '../services/language_service.dart';
import '../services/translations.dart';

class PendingStudentsScreen extends StatefulWidget {
  final String queueName;
  final String adminId;

  const PendingStudentsScreen({
    Key? key,
    required this.queueName,
    required this.adminId,
  }) : super(key: key);

  @override
  _PendingStudentsScreenState createState() => _PendingStudentsScreenState();
}

class _PendingStudentsScreenState extends State<PendingStudentsScreen> {
  bool _isLoading = true;
  List<dynamic> _pendingTokens = [];
  String _currentLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchPendingTokens();
  }

  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage(widget.adminId);
    if (mounted) {
      setState(() {
        _currentLanguage = lang;
      });
    }
  }

  Future<void> _fetchPendingTokens() async {
    // ✅ If queueName is empty, fetch pending by Admin ID (fallback mode)
    String url;
    if (widget.queueName.isEmpty) {
        if (widget.adminId.isNotEmpty) {
             url = "${ApiConfig.baseUrl}/pendingtokens/admin/${widget.adminId}";
        } else {
             // No context to fetch
             if (mounted) {
                setState(() {
                  _pendingTokens = [];
                  _isLoading = false;
                });
             }
             return;
        }
    } else {
        url = "${ApiConfig.baseUrl}/pendingtokens/${widget.queueName}";
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _pendingTokens = data["data"] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveToken(String tokenId) async {
    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/approvetoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"tokenId": tokenId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token approved successfully"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPendingTokens();
      }
    } catch (e) {}
  }

  Future<void> _rejectToken(String tokenId) async {
    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/rejecttoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "tokenId": tokenId,
          "reason": "Admin rejected the request",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token rejected"),
            backgroundColor: Colors.red,
          ),
        );
        _fetchPendingTokens();
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translations.translate('pending_student', _currentLanguage),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.queueName.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 80, color: Colors.orange.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "Queue is not active or not generated.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _pendingTokens.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            Translations.translate(
                              'no_pending_tokens',
                              _currentLanguage,
                            ),
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingTokens.length,
              itemBuilder: (context, index) {
                final token = _pendingTokens[index];
                final student = token['studentId'] ?? {};
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              student['name'] ?? "Unknown Student",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "#${token['tokenNumber']}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          student['email'] ?? "No email",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.description,
                          Translations.translate('purpose', _currentLanguage),
                          token['purpose'] ?? "N/A",
                        ),
                        _buildInfoRow(
                          Icons.access_time,
                          Translations.translate(
                            'generated_at',
                            _currentLanguage,
                          ),
                          token['generatedAt'] != null
                              ? DateFormat(
                                  'MMM dd, yyyy HH:mm',
                                ).format(DateTime.parse(token['generatedAt']))
                              : "N/A",
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveToken(token['_id']),
                                icon: const Icon(Icons.check),
                                label: Text(
                                  Translations.translate(
                                    'approve',
                                    _currentLanguage,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _rejectToken(token['_id']),
                                icon: const Icon(Icons.close),
                                label: Text(
                                  Translations.translate(
                                    'reject',
                                    _currentLanguage,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple[300]),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
