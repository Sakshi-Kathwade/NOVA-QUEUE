// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CurrentTokenScreen extends StatefulWidget {
  final String queueName;

  const CurrentTokenScreen({super.key, required this.queueName});

  @override
  State<CurrentTokenScreen> createState() => _CurrentTokenScreenState();
}

class _CurrentTokenScreenState extends State<CurrentTokenScreen> {
  bool isLoading = true;
  String? error;
  Timer? _pollTimer; // ✅ Timer for real-time updates

  String? tokenId; // ✅ Store token ID for actions
  int tokenNumber = 0;
  String studentName = "";
  String service = "";
  int completed = 0;
  int total = 0;
  bool isProcessing = false; // ✅ Prevent multiple clicks

  @override
  void initState() {
    super.initState();
    fetchCurrentToken();
    startPolling(); // ✅ Start real-time polling
  }

  @override
  void dispose() {
    _pollTimer?.cancel(); // ✅ Clean up timer
    super.dispose();
  }

  // ✅ REAL-TIME: Start polling for updates every 3 seconds
  void startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      fetchCurrentToken();
    });
  }

  Future<void> fetchCurrentToken() async {
    try {
      final url = Uri.parse(
        "http://localhost:8000/api/currenttoken/${widget.queueName}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final data = jsonData['data'];

        if (data == null) {
          // No active token
          setState(() {
            error = "No active token";
            isLoading = false;
          });
        } else {
          setState(() {
            tokenId = data['tokenId']?.toString();
            tokenNumber = data['tokenNumber'] ?? 0;
            studentName = data['studentName'] ?? "";
            service = data['purpose'] ?? "";
            completed = data['completedCount'] ?? 0;
            total = data['totalCount'] ?? 0;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = "No active token found";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Server error";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Current Token"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ---------- CURRENT TOKEN CARD ----------
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            "Now Serving",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error != null ? "No Token" : "Token - $tokenNumber",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error != null
                                ? "No student in queue"
                                : "Student: $studentName",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            error != null ? "" : "Service: $service",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ---------- PROGRESS ----------
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Queue Progress",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$completed of $total completed",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  /// ---------- HELD TOKENS BUTTON ----------
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pause_circle_outlined),
                    label: const Text("View Held Tokens"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => showHeldTokensDialog(),
                  ),

                  const SizedBox(height: 16),

                  /// ---------- ACTION BUTTONS ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.pause),
                        label: const Text("Hold"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            245,
                            166,
                            48,
                            1,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            (error != null || isProcessing || tokenId == null)
                            ? null
                            : () => holdToken(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Complete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            29,
                            187,
                            34,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            (error != null || isProcessing || tokenId == null)
                            ? null
                            : () => completeToken(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.skip_next),
                        label: const Text("Next"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: (error != null || isProcessing)
                            ? null
                            : () => nextToken(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // ✅ COMPLETE TOKEN
  Future<void> completeToken() async {
    if (tokenId == null || widget.queueName.isEmpty) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/completetoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"queueName": widget.queueName, "tokenId": tokenId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token completed successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh token data
        await fetchCurrentToken();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to complete token"),
            backgroundColor: Colors.red,
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

  // ✅ HOLD TOKEN
  Future<void> holdToken() async {
    if (tokenId == null || widget.queueName.isEmpty) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/holdtoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"queueName": widget.queueName, "tokenId": tokenId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token put on hold. You can unhold it later."),
            backgroundColor: Colors.orange,
          ),
        );

        // Refresh token data (will show next token)
        await fetchCurrentToken();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to hold token"),
            backgroundColor: Colors.red,
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

  // ✅ NEXT TOKEN
  Future<void> nextToken() async {
    if (widget.queueName.isEmpty) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/nexttoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": widget.queueName,
          "currentTokenId": tokenId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Next token loaded"),
            backgroundColor: Colors.blue,
          ),
        );

        // Refresh token data
        await fetchCurrentToken();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "No more tokens in queue"),
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

  // ✅ SHOW HELD TOKENS DIALOG
  Future<void> showHeldTokensDialog() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/heldtokens/${widget.queueName}"),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final heldTokens = data['heldTokens'] as List;

        if (heldTokens.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No tokens on hold"),
              backgroundColor: Colors.blue,
            ),
          );
          return;
        }

        // Show dialog with held tokens
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Held Tokens"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: heldTokens.length,
                itemBuilder: (context, index) {
                  final token = heldTokens[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          "A-${token['tokenNumber']}",
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(token['studentName'] ?? "Unknown"),
                      subtitle: Text(token['purpose'] ?? ""),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          unholdToken(token['tokenId']);
                        },
                        child: const Text("Unhold"),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error loading held tokens"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ UNHOLD TOKEN
  Future<void> unholdToken(String? heldTokenId) async {
    if (heldTokenId == null || widget.queueName.isEmpty) return;

    setState(() => isProcessing = true);

    try {
      final response = await http.put(
        Uri.parse("http://localhost:8000/api/unholdtoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "queueName": widget.queueName,
          "tokenId": heldTokenId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Token unheld successfully and returned to waiting queue",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh token data
        await fetchCurrentToken();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to unhold token"),
            backgroundColor: Colors.red,
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
}
