// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/language_service.dart';
import '../services/translations.dart';

class QueueHistoryScreen extends StatefulWidget {
  final String studentId;

  const QueueHistoryScreen({super.key, required this.studentId});

  @override
  State<QueueHistoryScreen> createState() => _QueueHistoryScreenState();
}

class _QueueHistoryScreenState extends State<QueueHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> historyData = [];
  String? _errorMsg;
  DateTime? selectedDate;
  String _currentLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchHistory();
  }

  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage(widget.studentId);
    if (mounted) {
      setState(() {
        _currentLanguage = lang;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/student/history/${widget.studentId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["history"] != null) {
          final List<dynamic> raw = data["history"];
          setState(() {
            historyData = raw.map<Map<String, dynamic>>((e) {
              final d = e["date"];
              return {
                "date": d != null ? DateTime.tryParse(d.toString()) ?? DateTime.now() : DateTime.now(),
                "serviceTaken": e["serviceTaken"] ?? "N/A",
                "queueName": e["queueName"] ?? "N/A",
                "tokenNumber": e["tokenNumber"] ?? 0,
                "waitingTimeMinutes": e["waitingTimeMinutes"] ?? 0,
                "status": e["status"] ?? "Served",
              };
            }).toList();
          });
        }
      } else {
        setState(() => _errorMsg = "Failed to load history");
      }
    } catch (e) {
      setState(() => _errorMsg = "Unable to connect");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredHistory {
    if (selectedDate == null) return historyData;
    return historyData.where((item) {
      final d = item["date"] as DateTime?;
      if (d == null) return false;
      return d.year == selectedDate!.year &&
          d.month == selectedDate!.month &&
          d.day == selectedDate!.day;
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(Translations.translate("queue_history", _currentLanguage)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: _pickDate),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => selectedDate = null),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(_errorMsg!, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchHistory,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : filteredHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            Translations.translate("no_queue_history_found", _currentLanguage),
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your past queue activities will appear here",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      color: Colors.deepPurple,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final entry = filteredHistory[index];
                          final isServed = (entry["status"] ?? "").toString().toLowerCase() == "served";
                          final date = entry["date"] as DateTime?;
                          final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : "—";

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isServed ? Colors.green.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isServed ? Icons.check_circle : Icons.cancel,
                                      color: isServed ? Colors.green : Colors.red,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry["serviceTaken"]?.toString() ?? "N/A",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text("Date: $dateStr", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                        Text(
                                          "Token: ${entry["tokenNumber"] ?? "—"}",
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                        ),
                                        Text(
                                          "Waiting: ${entry["waitingTimeMinutes"] ?? 0} min",
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      Translations.translate((entry["status"] ?? "").toString().toLowerCase(), _currentLanguage),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    backgroundColor: isServed ? Colors.green : Colors.red,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
