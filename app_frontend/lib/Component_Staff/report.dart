// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/translations.dart'; // Adjust path as needed

class ReportScreen extends StatefulWidget {
  final String? adminId;
  final String? adminEmail;

  const ReportScreen({super.key, this.adminId, this.adminEmail});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  final String _currentLanguage =
      'english'; // Assuming default language, will load from LanguageService

  // Report summary data
  int _totalTokensGenerated = 0;
  int _completedServicesToday = 0;
  int _averageWaitingTimeMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchReportsSummary();
  }

  Future<void> _loadLanguage() async {
    // Implement language loading if needed, similar to AdminSettingScreen
    // For now, assuming default 'english' or it's set globally
  }

  Future<void> _fetchReportsSummary() async {
    if (widget.adminId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/admin/reports/summary/${widget.adminId}",
        ),
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return; // Add mounted check immediately after await

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _totalTokensGenerated = data['totalTokensGenerated'] ?? 0;
            _completedServicesToday = data['completedServicesToday'] ?? 0;
            _averageWaitingTimeMinutes = data['averageWaitingTimeMinutes'] ?? 0;
          });
        } else {
          _showSnackBar(
            '${Translations.translate('failed_to_load_reports', _currentLanguage)}: ${data['message']}',
            Colors.red,
          );
        }
      } else {
        _showSnackBar(
          '${Translations.translate('failed_to_load_reports', _currentLanguage)}: ${json.decode(response.body)['message']}',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        // Only show snackbar if mounted
        _showSnackBar(
          '${Translations.translate('server_error', _currentLanguage)}: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(Translations.translate('reports', _currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : RefreshIndicator(
              onRefresh: _fetchReportsSummary,
              color: Colors.deepPurple,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Summary Section - Clean card layout
                  Text(
                    Translations.translate('summary', _currentLanguage),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.95,
                    children: [
                      _summaryCard(
                        title: Translations.translate(
                          'total_tokens_generated',
                          _currentLanguage,
                        ),
                        value: _totalTokensGenerated.toString(),
                        icon: Icons.confirmation_number,
                        color: Colors.blue,
                        gradient: const [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                      _summaryCard(
                        title: Translations.translate(
                          'completed_services_today',
                          _currentLanguage,
                        ),
                        value: _completedServicesToday.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                        gradient: const [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      ),
                      _summaryCard(
                        title: Translations.translate(
                          'average_waiting_time',
                          _currentLanguage,
                        ),
                        value:
                            "$_averageWaitingTimeMinutes ${Translations.translate('min', _currentLanguage)}",
                        icon: Icons.timer,
                        color: Colors.orange,
                        gradient: const [Color(0xFFFF9800), Color(0xFFF57C00)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Queue Statistics Section
                  Text(
                    Translations.translate(
                      'queue_statistics',
                      _currentLanguage,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                color: Colors.deepPurple,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                Translations.translate(
                                  'counter_performance',
                                  _currentLanguage,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Translations.translate(
                              'counter_performance_placeholder',
                              _currentLanguage,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.deepPurple,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                Translations.translate(
                                  'busy_hours',
                                  _currentLanguage,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Translations.translate(
                              'busy_hours_placeholder',
                              _currentLanguage,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    List<Color>? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              )
            : null,
        color: gradient == null ? color.withOpacity(0.1) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: gradient != null ? Colors.white : color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: gradient != null ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: gradient != null ? Colors.white70 : Colors.grey.shade700,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
