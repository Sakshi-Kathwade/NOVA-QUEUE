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
  final String _currentLanguage = 'english'; // Assuming default language, will load from LanguageService
  
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
        Uri.parse("http://localhost:8000/api/admin/reports/summary/${widget.adminId}"),
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
          _showSnackBar('${Translations.translate('failed_to_load_reports', _currentLanguage)}: ${data['message']}', Colors.red);
        }
      } else {
        _showSnackBar('${Translations.translate('failed_to_load_reports', _currentLanguage)}: ${json.decode(response.body)['message']}', Colors.red);
      }
    } catch (e) {
      if (mounted) { // Only show snackbar if mounted
        _showSnackBar('${Translations.translate('server_error', _currentLanguage)}: $e', Colors.red);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.translate('reports', _currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReportsSummary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary Cards
                  _sectionTitle(Translations.translate('summary', _currentLanguage)),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _summaryCard(
                        title: Translations.translate('total_tokens_generated', _currentLanguage),
                        value: _totalTokensGenerated.toString(),
                        icon: Icons.confirmation_number,
                        color: Colors.blueAccent,
                      ),
                      _summaryCard(
                        title: Translations.translate('completed_services_today', _currentLanguage),
                        value: _completedServicesToday.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _summaryCard(
                        title: Translations.translate('average_waiting_time', _currentLanguage),
                        value: "$_averageWaitingTimeMinutes ${Translations.translate('min', _currentLanguage)}",
                        icon: Icons.timer,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Counter-wise Performance (Placeholder)
                  _sectionTitle(Translations.translate('counter_performance', _currentLanguage)),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        Translations.translate('counter_performance_placeholder', _currentLanguage),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Busy Hours (Placeholder)
                  _sectionTitle(Translations.translate('busy_hours', _currentLanguage)),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        Translations.translate('busy_hours_placeholder', _currentLanguage),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
