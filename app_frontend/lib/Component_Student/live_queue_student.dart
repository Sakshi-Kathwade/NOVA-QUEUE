// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class LiveQueueStudent extends StatefulWidget {
  final String studentId;
  final String queueName;

  const LiveQueueStudent({
    super.key,
    required this.studentId,
    required this.queueName,
  });

  @override
  State<LiveQueueStudent> createState() => _LiveQueueStudentState();
}

class _LiveQueueStudentState extends State<LiveQueueStudent> {
  String queueName = "";
  int totalStudentsWaiting = 0;
  int myTokenNumber = 0;
  int averageWaitingTime = 0;
  int completedToday = 0;
  int studentsAhead = 0;
  bool isQueueOpen = true;
  String? currentlyServingToken;
  int? maxStudents; // ✅ Capture max students for progress bar
  List<Map<String, String>> liveQueueList = [];
  Timer? _pollTimer;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQueueData();
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
      final tokenRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/tokenget/$encodedQueue/${widget.studentId}"),
      );
      final currentRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/currenttoken/$encodedQueue"),
      );
      final remainingRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$encodedQueue"),
      );

      int fetchedMax = maxStudents ?? 0;
      int estimationConfigTime = 5;
      String? bStartStr;
      String? bEndStr;
      bool qOpen = isQueueOpen;
      DateTime? queueStartTime;

      try {
        final qRes = await http.get(
          Uri.parse("${ApiConfig.baseUrl}/queue"),
        );
        if (qRes.statusCode == 200) {
          final qd = jsonDecode(qRes.body);
          if (qd['success'] == true && qd['data'] != null) {
            List<dynamic> queues = qd['data'];
            for (var q in queues) {
              if (q['queueName'] == widget.queueName) {
                fetchedMax = q['maxStudents'] ?? 0;
                qOpen = q['status'] == "Active";
                if (q['startTime'] != null) queueStartTime = DateTime.parse(q['startTime']);
                String adminId = q['adminId'] ?? "";
                if (adminId.isNotEmpty) {
                   final stRes = await http.get(Uri.parse("${ApiConfig.baseUrl}/admin/settings/queue/$adminId"));
                   if (stRes.statusCode == 200) {
                      final stData = jsonDecode(stRes.body);
                      if (stData["success"] == true && stData["settings"] != null) {
                         estimationConfigTime = stData["settings"]["estimatedServiceTimePerStudent"] ?? 5;
                         bStartStr = stData["settings"]["breakStartTime"];
                         bEndStr = stData["settings"]["breakEndTime"];
                      }
                   }
                }
                break;
              }
            }
          } else {
             qOpen = false;
          }
        }
      } catch (e) {
        // ignore
      }

      int? servingToken;
      int completed = 0;
      if (currentRes.statusCode == 200) {
        final cur = jsonDecode(currentRes.body);
        if (cur["success"] == true) {
          if (cur["data"] != null) {
            servingToken = cur["data"]["tokenNumber"];
          }
          if (cur["data"] != null && cur["data"]["completedCount"] != null) {
            completed = cur["data"]["completedCount"];
          } else {
            completed = cur["completedCount"] ?? cur["completedToday"] ?? 0;
          }
        }
      }

      int totalWaiting = 0;
      List<Map<String, String>> queueList = [];
      
      int myToken = myTokenNumber;
      int fetchedStudentsAhead = 0;
      int fetchedEstTime = 0;
      bool hasToken = false;
      if (tokenRes.statusCode == 200) {
        final data = jsonDecode(tokenRes.body);
        if (data["success"] == true) {
           hasToken = true;
           myToken = data["tokenNumber"] ?? myToken;
           fetchedStudentsAhead = data["studentsAhead"] ?? 0;
           fetchedEstTime = data["estimatedWaitingTime"] ?? 0;
        }
      }

      int studentsAheadNum = 0;
      if (remainingRes.statusCode == 200) {
        final rem = jsonDecode(remainingRes.body);
        final waiting = (rem["waiting"] as List?) ?? [];
        totalWaiting = waiting.length;
        for (var w in waiting) {
          queueList.add({
            "token": "A-${w["tokenNumber"] ?? w["token"] ?? "?"}",
            "name": w["studentName"]?.toString() ?? w["name"]?.toString() ?? "—",
          });
        }
      }

      int estTime = 0;
      if (hasToken) {
         studentsAheadNum = fetchedStudentsAhead;
         estTime = fetchedEstTime;
      } else {
         studentsAheadNum = totalWaiting;
         estTime = studentsAheadNum * estimationConfigTime;
         
         // Apply break time delay if there is no token (so fall back computed)
         if (bStartStr != null && bEndStr != null && queueStartTime != null) {
             try {
                final now = DateTime.now();
                final bSParts = bStartStr.split(':');
                final bEParts = bEndStr.split(':');
                DateTime breakStart = DateTime(queueStartTime.year, queueStartTime.month, queueStartTime.day, int.parse(bSParts[0]), int.parse(bSParts[1]));
                DateTime breakEnd = DateTime(queueStartTime.year, queueStartTime.month, queueStartTime.day, int.parse(bEParts[0]), int.parse(bEParts[1]));
                
                DateTime tokenExpectedTime = now.add(Duration(minutes: estTime));
                if (tokenExpectedTime.isAfter(breakStart) && now.isBefore(breakEnd)) {
                    DateTime overlapStart = now.isAfter(breakStart) ? now : breakStart;
                    DateTime overlapEnd = tokenExpectedTime.isAfter(breakEnd) ? breakEnd : tokenExpectedTime;
                    int breakTimeToAdd = overlapEnd.difference(overlapStart).inMinutes;
                    if (breakTimeToAdd > 0) estTime += breakTimeToAdd;
                }
             } catch (e) {
                 // ignore parse errors
             }
         }
      }

      if (mounted) {
        setState(() {
          queueName = widget.queueName;
          totalStudentsWaiting = totalWaiting;
          completedToday = completed;
          myTokenNumber = myToken;
          averageWaitingTime = estTime;
          studentsAhead = studentsAheadNum;
          isQueueOpen = qOpen;
          currentlyServingToken = servingToken != null ? "A-$servingToken" : null;
          liveQueueList = queueList;
          if (fetchedMax > 0) maxStudents = fetchedMax;
          isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int estimatedTotalWait = totalStudentsWaiting * averageWaitingTime;
    int serving = currentlyServingToken != null ? int.tryParse(currentlyServingToken!.replaceAll("A-", "")) ?? 0 : 0;

    // ✅ Progress bar based on (Completed / MaxStudents) or fallback to current/myToken logic
    // Using max students gives a better "overall progress" view.
    // If user wants "progress to my turn", it would be different.
    // "according to max student like my token 5 and max studnet is the 20 and the according to that the progrssbar increase"
    // Interpretation: User wants progress of queue processing relative to TOTAL capacity.

    double progress = 0.0;

    if (maxStudents != null && maxStudents! > 0) {
      // Progress = Completed tokens / Max Capacity
      progress = (completedToday / maxStudents!).clamp(0.0, 1.0);
    } else if (myTokenNumber > 0 && serving > 0) {
      // Fallback: serving relative to my token
      progress = (serving >= myTokenNumber ? 1.0 : serving / myTokenNumber);
    } else if (myTokenNumber > 0) {
      // Fallback if just started
      progress = 0.0;
    }

    // Reset everything if queue closed/finished
    if (!isQueueOpen &&
        liveQueueList.isEmpty &&
        currentlyServingToken == null) {
      estimatedTotalWait = 0;
      progress = 0.0;
      serving = 0;
      myTokenNumber = 0;
      completedToday = 0;
      totalStudentsWaiting = 0;
      studentsAhead = 0;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Live Queue"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                            queueName.isNotEmpty ? queueName : widget.queueName,
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
                                isQueueOpen ? "Queue Open" : "Queue Closed",
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

            // Live status message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You are waiting in line",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Currently serving & Your token
            Row(
              children: [
                Expanded(
                  child: _highlightCard(
                    title: "Currently Serving",
                    value: currentlyServingToken ?? "—",
                    color: Colors.green,
                    icon: Icons.play_circle_filled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _highlightCard(
                    title: "Your Token",
                    value: myTokenNumber > 0 ? "A-$myTokenNumber" : "—",
                    color: Colors.deepPurple,
                    icon: Icons.confirmation_number,
                    isMine: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.people,
                    title: "Position Ahead",
                    value: studentsAhead.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    icon: Icons.check_circle,
                    title: "Completed Today",
                    value: completedToday.toString(),
                    color: Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.group,
                    title: "Max Students",
                    value: maxStudents?.toString() ?? "N/A",
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    icon: Icons.watch_later_outlined,
                    title: "Estimated Time",
                    value: "$averageWaitingTime Min",
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              "Queue Progress",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey.shade800,
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
                          "Progress",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation(
                        Colors.deepPurple,
                      ),
                    ),
                    Text(
                      "$completedToday out of ${maxStudents != null && maxStudents! > 0 ? maxStudents : (completedToday + liveQueueList.length)} students served today",
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (liveQueueList.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                "Queue Tokens",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 10),
              ...liveQueueList.asMap().entries.map((e) {
                final tokenStr = e.value["token"] ?? "—";
                final isMine = tokenStr == "A-$myTokenNumber";
                final isServing =
                    currentlyServingToken != null &&
                    tokenStr == currentlyServingToken;
                Color bg = Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey.shade100;
                if (isServing) bg = Colors.green.withOpacity(0.2);
                if (isMine) bg = Colors.deepPurple.withOpacity(0.2);
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
                      color: isMine
                          ? Colors.red
                          : (isServing ? Colors.green : Colors.grey.shade300),
                      width: isMine || isServing ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Highlight marker for "My Token"
                      if (isMine)
                        Container(
                          width: 4,
                          height: 30,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Icon(
                        isServing
                            ? Icons.play_circle_filled
                            : (isMine ? Icons.person : Icons.schedule),
                        color: isServing
                            ? Colors.green
                            : (isMine ? Colors.red : Colors.grey),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tokenStr,
                        style: TextStyle(
                          fontWeight: isMine || isServing
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 16,
                          color: isMine ? Colors.red.shade900 : Colors.black87,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "You",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                      if (isServing) ...[
                        const SizedBox(width: 8),
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
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
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
    bool isMine = false,
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
