// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ManageQueueScreen extends StatefulWidget {
  const ManageQueueScreen({super.key});

  @override
  State<ManageQueueScreen> createState() => _ManageQueueScreenState();
}

class _ManageQueueScreenState extends State<ManageQueueScreen> {
  // ✅ Queue State
  String? queueName;
  String? queueId;
  bool isQueueActive = false;
  bool isQueuePaused = false;

  // ✅ Current Token Data
  Map<String, dynamic>? currentToken;
  String? currentTokenId;
  int currentTokenNumber = 0;
  String currentStudentName = "N/A";
  String currentPurpose = "N/A";

  // ✅ Waiting Tokens List
  List<dynamic> waitingTokens = [];
  List<dynamic> holdTokens = [];

  // ✅ Analytics Data
  int completedToday = 0;
  int totalTokens = 0;
  double averageServiceTime = 0.0;
  int peakHour = 0;

  // ✅ UI State
  bool isLoading = true;
  bool isProcessing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchQueueData();
    // ✅ Start real-time refresh every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isProcessing) {
        fetchQueueData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ✅ FETCH ACTIVE QUEUE
  Future<void> fetchQueueData() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/activequeue"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true && data["data"] != null) {
          final queue = data["data"];
          setState(() {
            queueName = data["queueName"];
            queueId = queue["_id"];
            isQueueActive = queue["status"] == "Active";
            isLoading = false;
          });
          // ✅ Fetch token data
          await fetchCurrentToken();
          await fetchWaitingTokens();
          await fetchHeldTokens();
          await fetchAnalytics();
        } else {
          setState(() {
            isLoading = false;
            queueName = null;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ✅ FETCH CURRENT TOKEN
  Future<void> fetchCurrentToken() async {
    if (queueName == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/currenttoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true && data["data"] != null) {
          setState(() {
            currentToken = data["data"];
            currentTokenId = data["data"]["tokenId"];
            currentTokenNumber = data["data"]["tokenNumber"] ?? 0;
            currentStudentName = data["data"]["studentName"] ?? "N/A";
            currentPurpose = data["data"]["purpose"] ?? "N/A";
            completedToday = data["data"]["completedCount"] ?? 0;
            totalTokens = data["data"]["totalCount"] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching current token: $e");
    }
  }

  // ✅ FETCH WAITING TOKENS
  Future<void> fetchWaitingTokens() async {
    if (queueName == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/remainingtoken/$queueName"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final waitingList = (data["waiting"] as List?) ?? [];
        setState(() {
          waitingTokens = waitingList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching waiting tokens: $e");
    }
  }

  // ✅ FETCH HELD TOKENS
  Future<void> fetchHeldTokens() async {
    if (queueName == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/heldtokens/$queueName"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          final heldList = (data["heldTokens"] as List?) ?? [];
          setState(() {
            holdTokens = heldList;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching held tokens: $e");
    }
  }

  // ✅ FETCH ANALYTICS
  Future<void> fetchAnalytics() async {
    if (queueName == null) return;

    try {
      // Calculate average service time (mock for now, can be enhanced with backend)
      setState(() {
        averageServiceTime = completedToday > 0
            ? 5.0
            : 0.0; // 5 minutes average
        peakHour = DateTime.now().hour; // Current hour as peak
      });
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
    }
  }

  // ✅ ACTIVATE/PAUSE QUEUE
  Future<void> toggleQueueStatus() async {
    if (queueId == null) return;

    setState(() => isProcessing = true);

    try {
      final newStatus = isQueueActive ? "Inactive" : "Active";
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/queuestatus/$queueId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          isQueueActive = !isQueueActive;
          isQueuePaused = !isQueueActive;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isQueueActive ? "Queue Activated" : "Queue Paused"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update queue status"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // ✅ NEXT TOKEN
  Future<void> nextToken() async {
    if (queueName == null) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/nexttoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": queueName,
          "currentTokenId": currentTokenId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Next token loaded successfully"),
            backgroundColor: Colors.green,
          ),
        );
        await fetchCurrentToken();
        await fetchWaitingTokens();
        await fetchHeldTokens();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "No more tokens"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Server error. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // ✅ COMPLETE TOKEN
  Future<void> completeToken() async {
    if (queueName == null || currentTokenId == null) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/completetoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"queueName": queueName, "tokenId": currentTokenId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token completed successfully"),
            backgroundColor: Colors.green,
          ),
        );
        await fetchCurrentToken();
        await fetchWaitingTokens();
        await fetchHeldTokens();
        await fetchAnalytics();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to complete token"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // ✅ SKIP TOKEN
  Future<void> skipToken() async {
    if (queueName == null || currentTokenId == null) return;

    setState(() => isProcessing = true);

    try {
      // Mark current token as skipped and move to next
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/nexttoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": queueName,
          "currentTokenId": currentTokenId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token skipped. Moving to next token."),
            backgroundColor: Colors.orange,
          ),
        );
        await fetchCurrentToken();
        await fetchWaitingTokens();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to skip token"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // ✅ HOLD TOKEN
  Future<void> holdToken(String tokenId) async {
    if (queueName == null) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/holdtoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"queueName": queueName, "tokenId": tokenId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token put on hold"),
            backgroundColor: Colors.orange,
          ),
        );
        await fetchCurrentToken();
        await fetchWaitingTokens();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to hold token"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // ✅ UNHOLD TOKEN
  Future<void> unholdToken(String tokenId) async {
    if (queueName == null) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/unholdtoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"queueName": queueName, "tokenId": tokenId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token unheld successfully"),
            backgroundColor: Colors.green,
          ),
        );
        await fetchWaitingTokens();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to unhold token"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Manage Queue"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (queueName == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Manage Queue"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.queue_music, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No Active Queue",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please create a queue first",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Queue",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              queueName ?? "",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Queue Status Toggle with Material Design 3 style
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: isProcessing ? null : toggleQueueStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isQueueActive
                        ? Colors.green.shade400
                        : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isQueueActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isQueueActive ? "Active" : "Paused",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchQueueData,
        color: Colors.deepPurple,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ CURRENT TOKEN CARD
                    _buildCurrentTokenCard(),

                    // ✅ WAITING TOKENS SECTION
                    if (waitingTokens.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildWaitingTokensSection(),
                    ],

                    // ✅ HELD TOKENS (if any)
                    if (holdTokens.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildHeldTokensSection(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CURRENT TOKEN CARD - Enhanced & Professional
  Widget _buildCurrentTokenCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header with Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.confirmation_number,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Token",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentTokenNumber > 0
                                ? "A-$currentTokenNumber"
                                : "N/A",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isQueueActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: (isQueueActive ? Colors.green : Colors.grey)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isQueueActive
                              ? Icons.play_circle
                              : Icons.pause_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isQueueActive ? "ACTIVE" : "PAUSED",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ✅ Student Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoRowEnhanced(
                      "Student Name",
                      currentStudentName,
                      Icons.person,
                    ),
                    const Divider(height: 24),
                    _infoRowEnhanced(
                      "Purpose",
                      currentPurpose,
                      Icons.description,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Stats Row
              Row(
                children: [
                  Expanded(
                    child: _statCardEnhanced(
                      "Waiting",
                      waitingTokens.length.toString(),
                      Colors.orange,
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCardEnhanced(
                      "Completed",
                      completedToday.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ Action Buttons Row (Next, Complete, Skip)
              Row(
                children: [
                  Expanded(
                    child: _actionButtonEnhanced(
                      "Next",
                      Icons.skip_next,
                      Colors.deepPurple,
                      isProcessing || currentTokenNumber == 0
                          ? null
                          : nextToken,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButtonEnhanced(
                      "Complete",
                      Icons.check_circle,
                      Colors.green,
                      isProcessing || currentTokenNumber == 0
                          ? null
                          : completeToken,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButtonEnhanced(
                      "Skip",
                      Icons.skip_next_outlined,
                      Colors.orange,
                      isProcessing || currentTokenNumber == 0
                          ? null
                          : skipToken,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ HELD TOKENS SECTION
  Widget _buildHeldTokensSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Held Tokens",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Chip(
                  label: Text("${holdTokens.length}"),
                  backgroundColor: Colors.amber.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holdTokens.length,
              itemBuilder: (context, index) {
                final token = holdTokens[index];
                return _tokenListItem(
                  token: token,
                  isWaiting: false,
                  onUnhold: () => unholdToken(token["_id"] ?? ""),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ TOKEN LIST ITEM
  Widget _tokenListItem({
    required Map<String, dynamic> token,
    required bool isWaiting,
    VoidCallback? onHold,
    VoidCallback? onUnhold,
    VoidCallback? onPriority,
  }) {
    final tokenNumber = token["tokenNumber"] ?? 0;
    final studentName = token["studentName"] ?? "Unknown";
    final purpose = token["purpose"] ?? "N/A";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isWaiting ? Colors.orange : Colors.amber,
          child: Text(
            "A-$tokenNumber",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(purpose),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPriority != null)
              IconButton(
                icon: const Icon(Icons.star, color: Colors.amber),
                onPressed: onPriority,
                tooltip: "Set Priority",
              ),
            if (onHold != null)
              IconButton(
                icon: const Icon(Icons.pause_circle, color: Colors.amber),
                onPressed: onHold,
                tooltip: "Hold Token",
              ),
            if (onUnhold != null)
              IconButton(
                icon: const Icon(Icons.play_circle, color: Colors.green),
                onPressed: onUnhold,
                tooltip: "Unhold Token",
              ),
          ],
        ),
      ),
    );
  }

  // ✅ HELPER WIDGETS
  // ✅ Enhanced Info Row with Icon
  Widget _infoRowEnhanced(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCardEnhanced(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    Color lightColor;
    Color darkColor;

    // ✅ Map colors to their light variants
    if (color == Colors.orange) {
      lightColor = Colors.orange.shade50;
      darkColor = Colors.orange.shade700;
    } else if (color == Colors.green) {
      lightColor = Colors.green.shade50;
      darkColor = Colors.green.shade700;
    } else if (color == Colors.blue) {
      lightColor = Colors.blue.shade50;
      darkColor = Colors.blue.shade700;
    } else if (color == Colors.purple) {
      lightColor = Colors.purple.shade50;
      darkColor = Colors.purple.shade700;
    } else {
      lightColor = Colors.grey.shade100;
      darkColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: darkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced Action Button with better styling
  Widget _actionButtonEnhanced(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        elevation: onPressed == null ? 0 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
    );
  }
  

}