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

  // ✅ CURRENT TOKEN CARD - Modern Android Material Design 3
  Widget _buildCurrentTokenCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header Section
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.deepPurple.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current Token",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentTokenNumber > 0
                              ? "A-$currentTokenNumber"
                              : "No Token",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (currentTokenNumber > 0) ...[
                const SizedBox(height: 24),

                // ✅ Student Info Section - Material Design 3 style
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _infoRowMaterial(
                        Icons.person_outline_rounded,
                        "Student",
                        currentStudentName,
                      ),
                      const SizedBox(height: 16),
                      _infoRowMaterial(
                        Icons.description_outlined,
                        "Purpose",
                        currentPurpose,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Stats Row - Compact Material Design
                Row(
                  children: [
                    Expanded(
                      child: _statCardMaterial(
                        Icons.people_outline_rounded,
                        waitingTokens.length.toString(),
                        "Waiting",
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCardMaterial(
                        Icons.check_circle_outline_rounded,
                        completedToday.toString(),
                        "Completed",
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Action Buttons - Material Design 3 Filled Buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionButtonMaterial(
                        "Next",
                        Icons.skip_next_rounded,
                        Colors.deepPurple,
                        isProcessing ? null : nextToken,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButtonMaterial(
                        "Complete",
                        Icons.check_circle_rounded,
                        Colors.green,
                        isProcessing ? null : completeToken,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButtonMaterial(
                        "Skip",
                        Icons.skip_next_outlined,
                        Colors.orange,
                        isProcessing ? null : skipToken,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.queue_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No active token",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WAITING TOKENS SECTION - Material Design 3
  Widget _buildWaitingTokensSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.queue_rounded,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Waiting Queue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${waitingTokens.length}",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (waitingTokens.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No tokens waiting",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: waitingTokens.length > 10
                      ? 10
                      : waitingTokens.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final token = waitingTokens[index];
                    return _tokenListItemMaterial(
                      token: token,
                      isWaiting: true,
                      onHold: () => holdToken(token["_id"] ?? ""),
                    );
                  },
                ),
              if (waitingTokens.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      "+${waitingTokens.length - 10} more",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ HELD TOKENS SECTION - Material Design 3
  Widget _buildHeldTokensSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pause_circle_outline_rounded,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Held Tokens",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${holdTokens.length}",
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: holdTokens.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final token = holdTokens[index];
                  return _tokenListItemMaterial(
                    token: token,
                    isWaiting: false,
                    onUnhold: () => unholdToken(token["_id"] ?? ""),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ TOKEN LIST ITEM - Material Design 3
  Widget _tokenListItemMaterial({
    required Map<String, dynamic> token,
    required bool isWaiting,
    VoidCallback? onHold,
    VoidCallback? onUnhold,
  }) {
    final tokenNumber = token["tokenNumber"] ?? 0;
    final studentName = token["studentName"] ?? "Unknown";
    final purpose = token["purpose"] ?? "N/A";

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isWaiting ? Colors.orange.shade100 : Colors.amber.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "A-$tokenNumber",
              style: TextStyle(
                color: isWaiting
                    ? Colors.orange.shade700
                    : Colors.amber.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            purpose,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        trailing: onHold != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onHold,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.pause_circle_outline_rounded,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                  ),
                ),
              )
            : onUnhold != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onUnhold,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // ✅ HELPER WIDGETS - Material Design 3
  // ✅ Info Row Material Design 3
  Widget _infoRowMaterial(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple.shade700, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Stat Card Material Design 3
  Widget _statCardMaterial(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Action Button Material Design 3
  Widget _actionButtonMaterial(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return Material(
      color: onPressed != null ? color : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: onPressed != null ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onPressed != null
                      ? Colors.white
                      : Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
