// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/translations.dart'; // Import translations

class LiveQueuePreviewScreen extends StatefulWidget {
  final String? adminId;
  final String? activeQueueName; // The currently active queue name
  final List<Map<String, String>>
  initialQueueData; // Initial data, will be refreshed

  const LiveQueuePreviewScreen({
    super.key,
    this.adminId,
    this.activeQueueName,
    required this.initialQueueData,
  });

  @override
  State<LiveQueuePreviewScreen> createState() => _LiveQueuePreviewScreenState();
}

class _LiveQueuePreviewScreenState extends State<LiveQueuePreviewScreen> {
  bool _isLoading = true;
  List<Map<String, String>> _queueData = [];
  String _currentLanguage = 'english'; // Default language
  int? _currentlyServingToken; // Token number of the currently serving student
  Timer? _pollTimer;
  String? _currentQueueName; // The actual queue name we are displaying

  @override
  void initState() {
    super.initState();
    _queueData = widget.initialQueueData; // Initialize with passed data
    _currentQueueName = widget.activeQueueName;
    _loadLanguage();
    _fetchLiveQueueData();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchLiveQueueData(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    // In a real app, this would fetch from LanguageService based on adminId
    setState(() {
      _currentLanguage = 'english'; // For now, default to English
    });
  }

  Future<void> _fetchLiveQueueData() async {
    if (!mounted) return;

    if (widget.adminId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _queueData = [];
          _currentlyServingToken = null;
          _currentQueueName = null;
        });
      }
      return;
    }

    // First, confirm the active queue name for this admin
    String? confirmedQueueName = _currentQueueName;
    if (confirmedQueueName == null) {
      try {
        final queueResponse = await http.get(
          Uri.parse("http://localhost:8000/api/activequeue/${widget.adminId}"),
        );
        if (queueResponse.statusCode == 200) {
          final jsonData = json.decode(queueResponse.body);
          if (jsonData["success"] == true && jsonData["queueName"] != null) {
            confirmedQueueName = jsonData["queueName"];
          }
        }
      } catch (e) {
        debugPrint("Error fetching active queue name: $e");
      }
    }

    if (confirmedQueueName == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _queueData = [];
          _currentlyServingToken = null;
          _currentQueueName = null;
        });
      }
      return;
    }

    final encodedQueue = Uri.encodeComponent(confirmedQueueName);

    try {
      final currentTokenRes = await http.get(
        Uri.parse("http://localhost:8000/api/currenttoken/$encodedQueue"),
      );
      final remainingTokensRes = await http.get(
        Uri.parse("http://localhost:8000/api/remainingtoken/$encodedQueue"),
      );

      if (!mounted) return;

      int? servingToken;
      if (currentTokenRes.statusCode == 200) {
        final curData = json.decode(currentTokenRes.body);
        if (curData["success"] == true && curData["data"] != null) {
          servingToken = curData["data"]["tokenNumber"];
        }
      }

      List<Map<String, String>> updatedQueue = [];
      if (remainingTokensRes.statusCode == 200) {
        final remData = json.decode(remainingTokensRes.body);
        if (remData["success"] == true && remData["waiting"] != null) {
          final waitingList = (remData["waiting"] as List);
          // Include currently serving token at the top of the list for display logic
          if (servingToken != null) {
            final servingStudent = waitingList.firstWhere(
              (item) => item["tokenNumber"] == servingToken,
              orElse: () =>
                  <String, String>{}, // Provide an empty map if not found
            );
            if (servingStudent.isNotEmpty) {
              updatedQueue.add({
                "name": servingStudent["studentName"]?.toString() ?? "Unknown",
                "token": "A-${servingStudent["tokenNumber"]}",
                "status": "serving",
              });
            }
          }

          // Add remaining waiting students
          updatedQueue.addAll(
            waitingList
                .map<Map<String, String>>((item) {
                  // Avoid adding serving token again if already added
                  if (item["tokenNumber"] == servingToken)
                    return {}; // Empty map to be filtered out
                  return {
                    "name": item["studentName"]?.toString() ?? "Unknown",
                    "token": "A-${item["tokenNumber"]}",
                    "status": "waiting",
                  };
                })
                .where((e) => e.isNotEmpty)
                .toList(),
          );
        }
      }

      setState(() {
        _queueData = updatedQueue;
        _currentlyServingToken = servingToken;
        _currentQueueName = confirmedQueueName;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching live queue data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _queueData = [];
          _currentlyServingToken = null;
          _currentQueueName = confirmedQueueName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Translations.translate('live_queue_preview', _currentLanguage),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : RefreshIndicator(
              onRefresh: _fetchLiveQueueData,
              color: Colors.deepPurple,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Queue Name Card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.queue_play_next,
                                  color: Colors.deepPurple,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _currentQueueName != null &&
                                            _currentQueueName!.isNotEmpty
                                        ? _currentQueueName!
                                        : Translations.translate(
                                            'no_active_queue_admin',
                                            _currentLanguage,
                                          ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Currently Serving Card
                        if (_currentlyServingToken != null)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: EdgeInsets.zero,
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Translations.translate(
                                            'currently_serving',
                                            _currentLanguage,
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "A-${_currentlyServingToken!}",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: EdgeInsets.zero,
                            color: Colors.grey.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.grey.shade700,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      Translations.translate(
                                        'no_one_serving',
                                        _currentLanguage,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Total Students in Queue
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.shade100,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Translations.translate(
                                  'total_students_in_queue',
                                  _currentLanguage,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                              Text(
                                "${_queueData.length}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          Translations.translate(
                            'queue_list',
                            _currentLanguage,
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _queueData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_alt_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  Translations.translate('no_students_in_queue', _currentLanguage),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _queueData.length,
                            itemBuilder: (context, index) {
                              final student = _queueData[index];
                              final isServing = student["status"] == "serving";
                              final token = student["token"] ?? "—";
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isServing
                                        ? Colors.green.shade400
                                        : Colors.deepPurple.shade100,
                                    width: isServing ? 2 : 1,
                                  ),
                                ),
                                elevation: isServing ? 6 : 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isServing
                                        ? Colors.green
                                        : Colors.deepPurple,
                                    child: Text(
                                      token.split('-').last,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    student["name"] ??
                                        Translations.translate(
                                          'unknown_student',
                                          _currentLanguage,
                                        ),
                                    style: TextStyle(
                                      fontWeight: isServing
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 16,
                                      color: isServing
                                          ? Colors.green.shade900
                                          : Colors.deepPurple.shade800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isServing
                                        ? Translations.translate(
                                            'now_serving',
                                            _currentLanguage,
                                          )
                                        : Translations.translate(
                                            'waiting_in_queue',
                                            _currentLanguage,
                                          ),
                                    style: TextStyle(
                                      color: isServing
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: isServing
                                      ? Icon(
                                          Icons.waving_hand,
                                          color: Colors.green.shade700,
                                        )
                                      : Icon(
                                          Icons.access_time,
                                          color: Colors.deepPurple.shade400,
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
