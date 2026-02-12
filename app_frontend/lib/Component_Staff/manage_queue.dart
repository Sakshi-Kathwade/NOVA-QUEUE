// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class ManageQueueScreen extends StatefulWidget {
  final String? adminId;

  const ManageQueueScreen({super.key, this.adminId});

  @override
  State<ManageQueueScreen> createState() => _ManageQueueScreenState();
}

class _ManageQueueScreenState extends State<ManageQueueScreen> {
  String? queueName;
  String? queueId;
  String queueStatus = "Active";

  String? currentTokenId;
  int currentTokenNumber = 0;
  String studentName = "N/A";
  String purpose = "N/A";

  int waitingCount = 0;
  int completedCount = 0;

  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.adminId == null) {
      setState(() {
        isLoading = false;
        errorMessage = "Admin ID is missing";
      });
      return;
    }
    _initialize();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _fetchActiveQueue();
    if (queueName != null) {
      await _fetchCurrentToken();
      _startPolling();
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "No active queue found";
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _fetchCurrentToken(), // Refresh token and stats
    );
  }

  Future<void> _fetchActiveQueue() async {
    if (widget.adminId == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/activequeue/${widget.adminId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data["success"] == true && data["queueName"] != null) {
          setState(() {
            queueName = data["queueName"];
            queueId = data["data"]?["_id"];
            queueStatus = data["data"]?["status"] ?? "Active";
          });
        }
      }
    } catch (_) {
      // Silent fail for polling
    }
  }

  Future<void> _fetchCurrentToken() async {
    if (queueName == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/currenttoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            if (data["data"] != null) {
              currentTokenId = data["data"]["tokenId"];
              currentTokenNumber = data["data"]["tokenNumber"] ?? 0;
              studentName = data["data"]["studentName"] ?? "N/A";
              purpose = data["data"]["purpose"] ?? "N/A";
            } else {
              currentTokenId = null;
              currentTokenNumber = 0;
              studentName = "N/A";
              purpose = "N/A";
            }
            // Update stats from the same API call
            completedCount = data["data"]?["completedCount"] ?? 0;
            // pendingCount = data["data"]?["pendingCount"] ?? 0; // Not used in this screen but available
            isLoading = false;
          });
        }
        await _fetchWaitingCount();
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _fetchWaitingCount() async {
    if (queueName == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            waitingCount = data["waitingCount"] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleQueueStatus() async {
    if (queueId == null) return;

    setState(() => isProcessing = true);

    try {
      final newStatus = queueStatus == "Active" ? "Paused" : "Active";

      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/queuestatus/$queueId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": newStatus}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          setState(() => queueStatus = newStatus);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Queue is now $newStatus"),
              backgroundColor: newStatus == "Active" ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
         _showError(data['message'] ?? "Failed to update queue status");
      }
    } catch (e) {
      _showError("Server error. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _completeToken() async {
    if (currentTokenId == null || queueName == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active token to complete")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/completetoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"queueName": queueName, "tokenId": currentTokenId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Token completed successfully"),
              backgroundColor: Colors.green,
            ),
          );
          // Manually increment completed count for immediate feedback, poll will fix consistency
          setState(() {
            completedCount++;
          });
        }
        // Fetch next token immediately
        await _fetchCurrentToken();
        // Also try to load next token automatically if desired? 
        // For now, user has to click 'Next' to Serve the next one, 
        // unless we want 'Complete' to also auto-next. 
        // Based on typical flows, 'Complete' finishes one. 'Next' serves next.
      } else {
        _showError(data['message'] ?? "Failed to complete token");
      }
    } catch (e) {
      _showError("Server error. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _nextToken() async {
    if (queueName == null || widget.adminId == null) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/nexttoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "queueName": queueName,
          "currentTokenId": currentTokenId, // Pass current to auto-complete it if needed
          "adminId": widget.adminId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Now serving: ${data['data']['studentName'] ?? 'Student'}"),
              backgroundColor: Colors.blue,
            ),
          );
        }
        await _fetchCurrentToken();
      } else {
        _showError(data['message'] ?? "No more tokens available");
      }
    } catch (e) {
      _showError("Server error. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _holdToken() async {
    if (currentTokenId == null || queueName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active token to hold")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/holdtoken"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"queueName": queueName, "tokenId": currentTokenId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Token put on hold"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // After hold, we usually want to move to next, or just refresh to show "Empty/Waiting"
        await _fetchCurrentToken();
      } else {
         _showError(data['message'] ?? "Failed to hold token");
      }
    } catch (e) {
      _showError("Server error. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xff5E35B1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Queue",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(queueName ?? "No Queue", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: isProcessing ? null : _toggleQueueStatus,
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: queueStatus == "Active" ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    queueStatus == "Active" ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    queueStatus,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade100,
                        Colors.deepPurple.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xff5E35B1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.confirmation_number,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Current Token"),
                              Text(
                                currentTokenNumber > 0
                                    ? "A-$currentTokenNumber"
                                    : "N/A",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff5E35B1),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: queueStatus == "Active"
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              queueStatus.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            _infoRow(Icons.person, "Student Name", studentName),
                            const Divider(),
                            _infoRow(Icons.description, "Purpose", purpose),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          _statCard(
                            Icons.people,
                            waitingCount,
                            "Waiting",
                            Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            Icons.check_circle,
                            completedCount,
                            "Completed",
                            Colors.green,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      isProcessing
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _actionBtn(Icons.skip_next, "Next", _nextToken),
                                _actionBtn(
                                  Icons.check_circle,
                                  "Complete",
                                  _completeToken,
                                ),
                                _actionBtn(
                                  Icons.pause,
                                  "Hold",
                                  _holdToken,
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff5E35B1)),
        const SizedBox(width: 8),
        Text(title),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statCard(IconData icon, int count, String title, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade700),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
