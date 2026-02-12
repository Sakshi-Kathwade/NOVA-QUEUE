// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/language_service.dart';
import '../services/translations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../services/api_config.dart';

class CompletedTodayScreen extends StatefulWidget {
  final String? queueName;
  final String? adminId;

  const CompletedTodayScreen({super.key, this.queueName, this.adminId});

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

  Future<void> _loadLanguage() async {
    if (widget.adminId != null) {
      final lang = await LanguageService.getLanguage(widget.adminId!);
      setState(() {
        currentLanguage = lang;
      });
    }
  }

  void startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.queueName != null && widget.queueName!.isNotEmpty) {
        fetchCompletedToday();
      }
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, d MMMM y').format(now);
  }

  Future<void> fetchCompletedToday() async {
    if (widget.queueName == null || widget.queueName!.isEmpty) return;

    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/completedtoday/${widget.queueName}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          if (mounted) {
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
          }
        } else {
          if (mounted) {
            setState(() {
              totalCompleted = 0;
              hourlyData = [];
              completedTokens = [];
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            error = "Failed to load data";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = "Connection error";
        });
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      if (completedTokens.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.translate('no_data_to_export', currentLanguage),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final csvBuffer = StringBuffer();
      csvBuffer.writeln('Token,Student Name,Purpose,Completed At,Status');

      for (final item in completedTokens) {
        final tokenNumber = item['tokenNumber']?.toString() ?? 'N/A';
        final studentName = item['studentName'] ?? 'Unknown';
        final purpose = item['purpose'] ?? 'N/A';
        final completedAt = item['completedAt'] != null
            ? DateFormat('HH:mm:ss').format(DateTime.parse(item['completedAt']))
            : 'N/A';
        const status = 'Completed';

        csvBuffer.writeln(
          '"$tokenNumber","$studentName","$purpose","$completedAt","$status"',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'completed_today_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = io.File('${directory.path}/$fileName');
      await file.writeAsString(csvBuffer.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Daily Completion Report - ${_getFormattedDate()}',
        subject: 'Completed Today Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportToPDF() async {
    try {
      if (completedTokens.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.translate('no_data_to_export', currentLanguage),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Completed Today Report", // Cleaner English title for PDF
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          _getFormattedDate(),
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          "Queue: ${widget.queueName ?? 'N/A'}",
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          "Total: $totalCompleted",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _pdfCell('Token', isHeader: true),
                      _pdfCell('Student Name', isHeader: true),
                      _pdfCell('Purpose', isHeader: true),
                      _pdfCell('Time', isHeader: true),
                    ],
                  ),
                  ...completedTokens.map((item) {
                    final tokenNumber =
                        item['tokenNumber']?.toString() ?? 'N/A';
                    final studentName = item['studentName'] ?? 'Unknown';
                    final purpose = item['purpose'] ?? 'N/A';
                    final completedAt = item['completedAt'] != null
                        ? DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(item['completedAt']))
                        : 'N/A';

                    return pw.TableRow(
                      children: [
                        _pdfCell("A-$tokenNumber"),
                        _pdfCell(studentName),
                        _pdfCell(purpose),
                        _pdfCell(completedAt),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'completed_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = io.File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Daily Completion Report - ${_getFormattedDate()}',
        subject: 'Completed Today Report (PDF)',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Layout Helpers
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // ✅ User requested Grey.shade100
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple, // ✅ User requested DeepPurple
        foregroundColor: Colors.white, // ✅ User requested White text
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.translate('completed_today', currentLanguage),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              _getFormattedDate(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: Colors.deepPurple),
            tooltip: Translations.translate('export', currentLanguage),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) =>
                value == 'csv' ? _exportToCSV() : _exportToPDF(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      Translations.translate('export_as_csv', currentLanguage),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Translations.translate('export_as_pdf', currentLanguage),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(error!, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchCompletedToday,
                    child: Text(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOTAL COMPLETED CARD
                    _buildSummaryCard(isTablet),
                    const SizedBox(height: 20),

                    // HEADER FOR LIST
                    if (completedTokens.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 20,
                              color: Colors.deepPurple.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Recent Activity",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // LIST OF TOKENS
                    if (completedTokens.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: completedTokens.length,
                        itemBuilder: (context, index) {
                          final token = completedTokens[index];
                          return _buildTokenTile(token);
                        },
                      )
                    else
                      _buildEmptyState(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E24AA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.translate('completed_tokens', currentLanguage),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$totalCompleted",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 48 : 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Today",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: isTablet ? 48 : 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenTile(Map<String, dynamic> token) {
    final completedTime = token['completedAt'] != null
        ? DateFormat('h:mm a').format(DateTime.parse(token['completedAt']))
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            "${token['tokenNumber']}",
            style: TextStyle(
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          token['studentName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              token['purpose'] ?? 'General',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              completedTime,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No completions yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tokens completed today will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
