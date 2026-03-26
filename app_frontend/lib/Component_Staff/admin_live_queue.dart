// ignore_for_file: deprecated_member_use, use_build_context_synchronously, use_super_parameters, library_private_types_in_public_api, avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/language_service.dart';
import '../services/translations.dart';

class AdminLiveQueueScreen extends StatefulWidget {
  final String adminId;
  final String queueName;
  final int? maxStudents; // ✅ Accept maxStudents

  const AdminLiveQueueScreen({
    Key? key,
    required this.adminId,
    required this.queueName,
    this.maxStudents,
  }) : super(key: key);

  @override
  _AdminLiveQueueScreenState createState() => _AdminLiveQueueScreenState();
}

class _AdminLiveQueueScreenState extends State<AdminLiveQueueScreen> {
  int totalStudentsWaiting = 0;
  int completedToday = 0;
  String? currentlyServingToken;
  List<Map<String, String>> liveQueueList = [];
  Timer? _pollTimer;
  bool isLoading = true;
  String _currentLanguage = 'english';
  bool isQueueOpen = true;
  int estimationTime = 5; // default estimation time

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchQueueData(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final lang = await LanguageService.getLanguage(widget.adminId);
    if (mounted) {
      setState(() {
        _currentLanguage = lang;
      });
    }
    await fetchQueueData();
  }

  Future<void> fetchQueueData() async {
    if (widget.queueName.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    final encodedQueue = Uri.encodeComponent(widget.queueName);

    try {
      // Fetch queue status
      final queueRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/activequeue/${widget.adminId}"),
      );

      // Fetch current token and counts
      final currentRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/currenttoken/$encodedQueue"),
      );

      // Fetch remaining tokens (the actual queue list)
      final remainingRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$encodedQueue"),
      );

      // Fetch admin settings for estimated wait time
      final settingsRes = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/admin/settings/queue/${widget.adminId}",
        ),
      );

      if (!mounted) return;

      bool open = false;
      if (queueRes.statusCode == 200) {
        final qData = jsonDecode(queueRes.body);
        if (qData["success"] == true && qData["data"] != null) {
          open = qData["data"]["status"] == "Active";
        }
      }

      int serving = 0;
      int completed = 0;
      List<Map<String, String>> queueList = [];
      int fetchedEstimationTime = estimationTime;

      if (settingsRes.statusCode == 200) {
        final stData = jsonDecode(settingsRes.body);
        if (stData["success"] == true && stData["settings"] != null) {
          fetchedEstimationTime =
              stData["settings"]["estimatedServiceTimePerStudent"] ?? 5;
        }
      }

      if (currentRes.statusCode == 200) {
        final cur = jsonDecode(currentRes.body);
        if (cur["success"] == true) {
          if (cur["data"] != null) {
            serving = cur["data"]["tokenNumber"] ?? 0;
          }

          if (cur["data"] != null && cur["data"]["completedCount"] != null) {
            completed = cur["data"]["completedCount"];
          } else {
            completed = cur["completedCount"] ?? cur["completedToday"] ?? 0;
          }
        }
      }

      if (remainingRes.statusCode == 200) {
        final rem = jsonDecode(remainingRes.body);
        if (rem["success"] == true) {
          final waiting = (rem["waiting"] as List?) ?? [];
          for (var w in waiting) {
            queueList.add({
              "token": "A-${w["tokenNumber"] ?? w["token"] ?? "?"}",
              "name":
                  w["studentName"]?.toString() ?? w["name"]?.toString() ?? "—",
              "status": (w["tokenNumber"] == serving) ? "serving" : "waiting",
            });
          }
        }
      }

      setState(() {
        currentlyServingToken = serving > 0 ? "A-$serving" : null;
        completedToday = completed;
        totalStudentsWaiting = queueList
            .where((e) => e["status"] == "waiting")
            .length;
        liveQueueList = queueList;
        isQueueOpen = open;
        estimationTime = fetchedEstimationTime;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching admin live queue: $e");
      if (isLoading && mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // For Admin progress
    // Use maxStudents if available, otherwise totalToday
    int totalToday = completedToday + liveQueueList.length;
    int denominator = (widget.maxStudents != null && widget.maxStudents! > 0)
        ? widget.maxStudents!
        : totalToday;

    double progress = denominator > 0
        ? (completedToday / denominator).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(Translations.translate('live_queue', _currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchQueueData,
          ),
        ],
      ),
      body: widget.queueName.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.orange.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Queue is not active or not generated.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Queue name & status
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.queue,
                            size: 40,
                            color: Colors.deepPurple.shade700,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.queueName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isQueueOpen
                                            ? Colors.green
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isQueueOpen
                                                        ? Colors.green
                                                        : Colors.red)
                                                    .withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isQueueOpen
                                          ? "Queue Open"
                                          : "Queue Closed",
                                      style: TextStyle(
                                        color: isQueueOpen
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Highlights
                  Row(
                    children: [
                      Expanded(
                        child: _highlightCard(
                          title: Translations.translate(
                            'currently_serving',
                            _currentLanguage,
                          ),
                          value: currentlyServingToken ?? "—",
                          color: Colors.green,
                          icon: Icons.play_circle_filled,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _highlightCard(
                          title: Translations.translate(
                            'students_waiting',
                            _currentLanguage,
                          ),
                          value: totalStudentsWaiting.toString(),
                          color: Colors.orange,
                          icon: Icons.people,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          icon: Icons.check_circle,
                          title: Translations.translate(
                            'completed_today',
                            _currentLanguage,
                          ),
                          value: completedToday.toString(),
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          icon: Icons.group,
                          title: "Max Students",
                          value: widget.maxStudents?.toString() ?? "N/A",
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Progress
                  Text(
                    "Daily Progress",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Served Students",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                              ),
                              Text(
                                "${(progress * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]
                                : Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$completedToday out of ${widget.maxStudents ?? totalToday} students served today",
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (liveQueueList.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      Translations.translate('queue_list', _currentLanguage),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...liveQueueList.map((e) {
                      final isServing = e["status"] == "serving";
                      Color bg = Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]!
                          : Colors.grey.shade100;
                      if (isServing) bg = Colors.green.withOpacity(0.2);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isServing
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: isServing ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isServing
                                  ? Icons.play_circle_filled
                                  : Icons.schedule,
                              color: isServing ? Colors.green : Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e["name"] ?? "—",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isServing
                                          ? Colors.green
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    e["token"] ?? "—",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isServing) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Serving",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Translations.translate(
                              'no_students_in_queue',
                              _currentLanguage,
                            ),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _highlightCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
