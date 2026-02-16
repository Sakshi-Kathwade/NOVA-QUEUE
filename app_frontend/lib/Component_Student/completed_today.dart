// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../services/language_service.dart';
import '../services/translations.dart';
import 'package:intl/intl.dart';

class CompletedTodayScreen extends StatefulWidget {
  final String? queueName;
  final String? studentId;

  const CompletedTodayScreen({super.key, this.queueName, this.studentId});

  @override
  State<CompletedTodayScreen> createState() => _CompletedTodayScreenState();
}

class _CompletedTodayScreenState extends State<CompletedTodayScreen> {
  bool isLoading = true;
  String? error;
  int totalCompleted = 0;
  List<Map<String, dynamic>> hourlyData = [];
  List<Map<String, dynamic>> completedTokens = [];
  Timer? _refreshTimer;
  String currentLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    if (widget.queueName != null && widget.queueName!.isNotEmpty) {
      fetchCompletedToday();
      startAutoRefresh();
    } else {
      setState(() {
        isLoading = false;
        error = "Queue not active";
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ✅ Load user's language preference
  Future<void> _loadLanguage() async {
    if (widget.studentId != null) {
      final lang = await LanguageService.getLanguage(widget.studentId!);
      setState(() {
        currentLanguage = lang;
      });
    }
  }

  // ✅ Start auto-refresh every 10 seconds
  void startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (widget.queueName != null && widget.queueName!.isNotEmpty) {
        fetchCompletedToday();
      }
    });
  }

  // ✅ Get Formatted Date
  String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, d MMMM').format(now);
  }

  // ✅ Fetch completed tokens today from backend
  Future<void> fetchCompletedToday() async {
    if (widget.queueName == null || widget.queueName!.isEmpty) {
      setState(() {
        isLoading = false;
        error = "Queue is not active or not generated";
      });
      return;
    }

    try {
      final url = Uri.parse(
        "http://localhost:8000/api/completedtoday/${widget.queueName}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          setState(() {
            totalCompleted = data['totalCompleted'] ?? 0;
            hourlyData = List<Map<String, dynamic>>.from(
              data['hourlyBreakdown'] ?? [],
            );
            completedTokens = List<Map<String, dynamic>>.from(
              data['completedTokens'] ?? [],
            );
            isLoading = false;
            error = null;
          });
        } else {
          setState(() {
            totalCompleted = 0;
            hourlyData = [];
            completedTokens = [];
            isLoading = false;
            error = null;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          error = "Failed to load data";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = "Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.translate('completed_today', currentLanguage),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _getFormattedDate(), // ✅ Display Date & Day
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCompletedToday,
            tooltip: Translations.translate('refresh', currentLanguage),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(Translations.translate('loading', currentLanguage)),
                ],
              ),
            )
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: fetchCompletedToday,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      Translations.translate('refresh', currentLanguage),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchCompletedToday,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ✅ TOTAL COMPLETED CARD - Responsive
                    _buildTotalCompletedCard(isTablet),
                    const SizedBox(height: 24),



                    // ✅ COMPLETED TOKENS LIST - Responsive
                    if (completedTokens.isNotEmpty) ...[
                      _buildCompletedTokensList(isTablet),
                    ],

                    // ✅ EMPTY STATE
                    if (totalCompleted == 0 && hourlyData.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  // ✅ Total Completed Card - Simplified
  Widget _buildTotalCompletedCard(bool isTablet) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: isTablet ? 56 : 48,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.translate('completed_tokens', currentLanguage),
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$totalCompleted",
                    style: TextStyle(
                      fontSize: isTablet ? 42 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translations.translate('today', currentLanguage),
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ✅ Completed Tokens List - Responsive
  Widget _buildCompletedTokensList(bool isTablet) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: Colors.deepPurple,
                  size: isTablet ? 24 : 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "Recent Completions",
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...completedTokens.take(10).map((token) {
              final completedTime = token['completedAt'] != null
                  ? DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(token['completedAt']))
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "A-${token['tokenNumber'] ?? 'N/A'}",
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            token['studentName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            token['purpose'] ?? '',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (completedTime.isNotEmpty)
                      Text(
                        completedTime,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: isTablet ? 24 : 20,
                    ),
                  ],
                ),
              );
            }),
            if (completedTokens.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "+ ${completedTokens.length - 10} more",
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Empty State
  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              Translations.translate('no_data_available', currentLanguage),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No tokens have been completed today yet.",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
