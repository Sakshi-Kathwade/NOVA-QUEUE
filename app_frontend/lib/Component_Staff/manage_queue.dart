// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/translations.dart';
import '../services/language_service.dart';

class ManageQueueScreen extends StatefulWidget {
  final String? initialQueueName;
  final String? initialQueueId;
  final String? adminId;

  const ManageQueueScreen({
    super.key,
    this.initialQueueName,
    this.initialQueueId,
    this.adminId,
  });

  @override
  State<ManageQueueScreen> createState() => _ManageQueueScreenState();
}

class _ManageQueueScreenState extends State<ManageQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollTimer;
  bool isLoading = true;
  String? error;
  String currentLanguage = 'english';

  // Queue State
  String? queueId;
  String? queueName;
  String queueStatus = "Inactive";
  int waitingCount = 0;
  int completedCount = 0;
  int pendingCount = 0;
  int totalCount = 0;

  // Current Token State
  Map<String, dynamic>? currentToken;
  bool isProcessing = false;

  // Lists
  List<dynamic> waitingList = [];
  List<dynamic> heldList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    queueId = widget.initialQueueId;
    queueName = widget.initialQueueName;
    _loadLanguage();
    fetchData();
    startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    if (widget.adminId != null) {
      final lang = await LanguageService.getLanguage(widget.adminId!);
      setState(() {
        currentLanguage = lang;
      });
    }
  }

  void startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isProcessing) {
        fetchData();
      }
    });
  }

  Future<void> fetchData() async {
    if (queueName == null || queueName!.isEmpty) {
      // Try to fetch active queue if not provided
      await _fetchActiveQueue();
      if (queueName == null) return;
    }

    await Future.wait([
      _fetchQueueStatus(),
      _fetchCurrentToken(),
      _fetchWaitingList(),
      _fetchHeldTokens(),
    ]);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchActiveQueue() async {
    if (widget.adminId == null) return;
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/activequeue/${widget.adminId}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            queueId = data['data']['_id'];
            queueName = data['data']['queueName'];
            queueStatus = data['data']['status'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching active queue: $e");
    }
  }

  Future<void> _fetchQueueStatus() async {
    if (widget.adminId == null) return;
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/activequeue/${widget.adminId}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            queueStatus = data['data']['status'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching queue status: $e");
    }
  }

  Future<void> _fetchCurrentToken() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/currenttoken/$queueName"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentToken = data['data'];
          completedCount = data['completedCount'] ?? 0;
          pendingCount = data['pendingCount'] ?? 0;
          totalCount = data['totalCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching current token: $e");
    }
  }

  Future<void> _fetchWaitingList() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/remainingtoken/$queueName"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          waitingList = data['waiting'] ?? [];
          waitingCount = waitingList.length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching waiting list: $e");
    }
  }

  Future<void> _fetchHeldTokens() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/heldtokens/$queueName"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          heldList = data['heldTokens'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching held tokens: $e");
    }
  }

  Future<void> _updateQueueStatus(String status) async {
    if (queueId == null) return;
    setState(() => isProcessing = true);
    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/queuestatus/$queueId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
      if (response.statusCode == 200) {
        setState(() {
          queueStatus = status;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Queue $status")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error updating status")));
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _handleTokenAction(String action, {String? tokenId}) async {
    setState(() => isProcessing = true);
    try {
      String url = "";
      Map<String, dynamic> body = {"queueName": queueName};

      if (action == "complete") {
        url = "${ApiConfig.baseUrl}/completetoken";
        body["tokenId"] = tokenId ?? currentToken?['tokenId'];
      } else if (action == "hold") {
        url = "${ApiConfig.baseUrl}/holdtoken";
        body["tokenId"] = tokenId ?? currentToken?['tokenId'];
      } else if (action == "unhold") {
        url = "${ApiConfig.baseUrl}/unholdtoken";
        body["tokenId"] = tokenId;
      } else if (action == "next") {
        url = "${ApiConfig.baseUrl}/nexttoken";
        body["currentTokenId"] = currentToken?['tokenId'];
        body["adminId"] = widget.adminId;
      } else if (action == "missed") {
        url = "${ApiConfig.baseUrl}/markmissedtoken";
        body["tokenId"] = tokenId ?? currentToken?['tokenId'];
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Action successful"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Action failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error performing action"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && queueName == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Manage Queue")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              queueName ?? "Manage Queue",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              queueStatus,
              style: TextStyle(
                fontSize: 12,
                color: queueStatus == "Active"
                    ? Colors.greenAccent
                    : Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchData),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          _buildCurrentTokenCard(),
          _buildQueueControls(),
          const SizedBox(height: 10),
          _buildTabsHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildWaitingList(), _buildHeldList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statItem("Waiting", waitingCount.toString(), Colors.orange),
          _statItem("Completed", completedCount.toString(), Colors.green),
          _statItem("Pending", pendingCount.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTokenCard() {
    bool hasToken = currentToken != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.deepPurple.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: hasToken
                  ? [Colors.deepPurple, Colors.deepPurpleAccent]
                  : [Colors.grey[400]!, Colors.grey[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "NOW SERVING",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (hasToken)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "LIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  hasToken ? "A-${currentToken!['tokenNumber']}" : "---",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasToken
                      ? (currentToken!['studentName'] ?? "Unknown Student")
                      : "No Active Token",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  hasToken
                      ? (currentToken!['purpose'] ?? "General Inquiry")
                      : "Call next student to start",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                if (hasToken)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        Icons.pause,
                        "Hold",
                        Colors.orange,
                        () => _handleTokenAction("hold"),
                      ),
                      _actionButton(
                        Icons.check_circle,
                        "Complete",
                        Colors.green,
                        () => _handleTokenAction("complete"),
                      ),
                      _actionButton(
                        Icons.close,
                        "Missed",
                        Colors.red,
                        () => _handleTokenAction("missed"),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _handleTokenAction("next"),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("CALL NEXT STUDENT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: isProcessing ? null : onPressed,
          icon: Icon(icon, color: Colors.white, size: 28),
          style: IconButton.styleFrom(backgroundColor: Colors.white24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildQueueControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlBtn(
            "Pause",
            Icons.pause,
            Colors.orange,
            queueStatus == "Active",
            () => _updateQueueStatus("Paused"),
          ),
          _controlBtn(
            "Resume",
            Icons.play_arrow,
            Colors.green,
            queueStatus == "Paused",
            () => _updateQueueStatus("Active"),
          ),
          _controlBtn(
            "Stop",
            Icons.stop,
            Colors.red,
            queueStatus != "Inactive",
            () => _updateQueueStatus("Inactive"),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(
    String label,
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: enabled && !isProcessing ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: enabled ? color : Colors.grey),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTabsHeader() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.deepPurple,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.deepPurple,
        tabs: const [
          Tab(text: "Waiting List"),
          Tab(text: "Held Tokens"),
        ],
      ),
    );
  }

  Widget _buildWaitingList() {
    if (waitingList.isEmpty) {
      return const Center(
        child: Text(
          "No students waiting",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: waitingList.length,
      itemBuilder: (context, index) {
        final student = waitingList[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade50,
              child: Text(
                "${student['tokenNumber']}",
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(student['studentName'] ?? "Unknown"),
            subtitle: Text(student['purpose'] ?? ""),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'hold', child: Text("Put on Hold")),
                const PopupMenuItem(value: 'remove', child: Text("Remove")),
              ],
              onSelected: (val) {
                // Implement specific student actions if needed
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeldList() {
    if (heldList.isEmpty) {
      return const Center(
        child: Text("No tokens on hold", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: heldList.length,
      itemBuilder: (context, index) {
        final token = heldList[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade100),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: Text(
                "${token['tokenNumber']}",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(token['studentName'] ?? "Unknown"),
            subtitle: Text(token['purpose'] ?? ""),
            trailing: ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () =>
                        _handleTokenAction("unhold", tokenId: token['tokenId']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(60, 30),
              ),
              child: const Text("Unhold", style: TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }
}
