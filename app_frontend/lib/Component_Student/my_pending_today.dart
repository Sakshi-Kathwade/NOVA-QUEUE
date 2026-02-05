// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/language_service.dart';
import '../services/translations.dart';

class MyPendingToday extends StatefulWidget {
  final String queueName;
  final String studentId;

  const MyPendingToday({
    Key? key,
    required this.queueName,
    required this.studentId,
  }) : super(key: key);

  @override
  _MyPendingTodayState createState() => _MyPendingTodayState();
}

class _MyPendingTodayState extends State<MyPendingToday> {
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
    final lang = await LanguageService.getLanguage(widget.studentId);
    if (mounted) {
      setState(() {
        _currentLanguage = lang;
      });
    }
  }

  Future<void> _fetchPendingTokens() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/student/pending/${widget.studentId}",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pendingTokens = data["data"] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching pending tokens: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translations.translate('student_pending_today', _currentLanguage),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingTokens.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 80,
                    color: Colors.grey[400],
                  ),
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
                              "Token #${token['tokenNumber']}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Text(
                                Translations.translate(
                                  'pending',
                                  _currentLanguage,
                                ),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.queue,
                          Translations.translate('queue', _currentLanguage),
                          token['queueName'] ?? "N/A",
                        ),
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
                        const SizedBox(height: 12),
                        Text(
                          "Your request is currently under review by the admin. Please wait for approval.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
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
