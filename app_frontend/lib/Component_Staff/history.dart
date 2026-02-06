import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' as io; // Alias for dart:io
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../services/language_service.dart';
import '../services/translations.dart';

class HistoryScreen extends StatefulWidget {
  final String? adminId;
  final String? adminEmail;

  const HistoryScreen({super.key, this.adminId, this.adminEmail});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _historyData = [];
  String _currentLanguage = 'english'; // Changed to non-final

  // Filter states
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Default to today
    _loadLanguage(); // Fetch language
    _fetchQueueHistory();
  }

  // ✅ Load user's language preference
  Future<void> _loadLanguage() async {
    if (widget.adminId != null) {
      final lang = await LanguageService.getLanguage(widget.adminId!);
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
      }
    }
  }

  // Fetch queue history data from backend
  Future<void> _fetchQueueHistory() async {
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
      String url = "http://localhost:8000/api/admin/history/${widget.adminId}";
      if (_selectedDate != null) {
        url += "?date=${DateFormat('yyyy-MM-dd').format(_selectedDate!)}";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return; // Add mounted check immediately after await

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            _historyData = data["history"];
          });
        } else {
          _showSnackBar(
            '${Translations.translate('failed_to_load_history', _currentLanguage)}: ${data['message']}', // Interpolated string
            Colors.red,
          );
        }
      } else {
        _showSnackBar(
          '${Translations.translate('failed_to_load_history', _currentLanguage)}: ${json.decode(response.body)['message']}', // Interpolated string
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        // Only show snackbar if mounted
        _showSnackBar(
          '${Translations.translate('server_error', _currentLanguage)}: $e', // Interpolated string
          Colors.red,
        );
      }
      debugPrint("Error fetching history: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Pick date
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchQueueHistory(); // Fetch history for the new date
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
        title: Text(Translations.translate('queue_history', _currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: Translations.translate('export', _currentLanguage),
            onSelected: (value) {
              if (value == 'csv') {
                _exportToCSV();
              } else if (value == 'pdf') {
                _exportToPDF();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      Translations.translate('export_as_csv', _currentLanguage),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      Translations.translate('export_as_pdf', _currentLanguage),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchQueueHistory,
            tooltip: Translations.translate('refresh', _currentLanguage),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: Text(
                "${Translations.translate('date', _currentLanguage)}: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 30,
                ),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _historyData.isEmpty
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ), // Removed io.
                        const SizedBox(height: 16),
                        Text(
                          Translations.translate(
                            'no_history_records_found',
                            _currentLanguage,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchQueueHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _historyData.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_historyData[index]);
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // Export to CSV
  Future<void> _exportToCSV() async {
    try {
      if (_historyData.isEmpty) {
        _showSnackBar(
          Translations.translate('no_data_to_export', _currentLanguage),
          Colors.orange,
        );
        return;
      }

      final csvBuffer = StringBuffer();
      csvBuffer.writeln(
        'Token Number,Service,Queue,Status,Generated At,Completed/Cancelled At,Counter,Staff,Student Name,Student Email',
      );

      for (final item in _historyData) {
        final tokenNumber = item['tokenNumber']?.toString() ?? 'N/A';
        final serviceName = item['serviceId']?['serviceName'] ?? 'N/A';
        final queueName = item['queueId']?['queueName'] ?? 'N/A';
        final status = item['status'] ?? 'N/A';
        final generatedAt = item['generatedAt'] != null
            ? DateFormat(
                'yyyy-MM-dd HH:mm:ss',
              ).format(DateTime.parse(item['generatedAt']))
            : 'N/A';
        final completedOrCancelledAt = (item['completedAt'] != null)
            ? DateFormat(
                'yyyy-MM-dd HH:mm:ss',
              ).format(DateTime.parse(item['completedAt']))
            : (item['cancelledAt'] != null)
            ? DateFormat(
                'yyyy-MM-dd HH:mm:ss',
              ).format(DateTime.parse(item['cancelledAt']))
            : 'N/A';
        final counterName = item['counterId']?['counterName'] ?? 'N/A';
        final staffName = item['staffId']?['name'] ?? 'N/A';
        final studentName = item['studentId']?['name'] ?? 'N/A';
        final studentEmail = item['studentId']?['email'] ?? 'N/A';

        csvBuffer.writeln(
          '"$tokenNumber","$serviceName","$queueName","$status","$generatedAt","$completedOrCancelledAt","$counterName","$staffName","$studentName","$studentEmail"',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'queue_history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = io.File('${directory.path}/$fileName');
      await file.writeAsString(csvBuffer.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: Translations.translate('queue_history_export', _currentLanguage),
        subject: Translations.translate('history_csv_export', _currentLanguage),
      );

      if (mounted) {
        _showSnackBar(
          '${Translations.translate('csv_exported_successfully', _currentLanguage)}: $fileName', // Interpolated string
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '${Translations.translate('error_exporting_csv', _currentLanguage)}: $e', // Interpolated string
          Colors.red,
        );
      }
    }
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    try {
      if (_historyData.isEmpty) {
        _showSnackBar(
          Translations.translate('no_data_to_export', _currentLanguage),
          Colors.orange,
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
                      Translations.translate(
                        'queue_history_report',
                        _currentLanguage,
                      ),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                '${Translations.translate('total_records', _currentLanguage)}: ${_historyData.length}', // Interpolated string
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell(
                        Translations.translate(
                          'token_number',
                          _currentLanguage,
                        ),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate('service', _currentLanguage),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate('queue', _currentLanguage),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate('status', _currentLanguage),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate(
                          'generated_at',
                          _currentLanguage,
                        ),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate(
                          'completed_cancelled_at',
                          _currentLanguage,
                        ),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate('counter', _currentLanguage),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate('staff', _currentLanguage),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate(
                          'student_name',
                          _currentLanguage,
                        ),
                        isHeader: true,
                      ),
                      _buildTableCell(
                        Translations.translate(
                          'student_email',
                          _currentLanguage,
                        ),
                        isHeader: true,
                      ),
                    ],
                  ),
                  ..._historyData.map((item) {
                    final tokenNumber =
                        item['tokenNumber']?.toString() ?? 'N/A';
                    final serviceName =
                        item['serviceId']?['serviceName'] ?? 'N/A';
                    final queueName = item['queueId']?['queueName'] ?? 'N/A';
                    final status = item['status'] ?? 'N/A';
                    final generatedAt = item['generatedAt'] != null
                        ? DateFormat(
                            'MMM dd, HH:mm',
                          ).format(DateTime.parse(item['generatedAt']))
                        : 'N/A';
                    final completedOrCancelledAt = (item['completedAt'] != null)
                        ? DateFormat(
                            'MMM dd, HH:mm',
                          ).format(DateTime.parse(item['completedAt']))
                        : (item['cancelledAt'] != null)
                        ? DateFormat(
                            'MMM dd, HH:mm',
                          ).format(DateTime.parse(item['cancelledAt']))
                        : 'N/A';
                    final counterName =
                        item['counterId']?['counterName'] ?? 'N/A';
                    final staffName = item['staffId']?['name'] ?? 'N/A';
                    final studentName = item['studentId']?['name'] ?? 'N/A';
                    final studentEmail = item['studentId']?['email'] ?? 'N/A';

                    return pw.TableRow(
                      children: [
                        _buildTableCell(tokenNumber),
                        _buildTableCell(serviceName),
                        _buildTableCell(queueName),
                        _buildTableCell(status),
                        _buildTableCell(generatedAt),
                        _buildTableCell(completedOrCancelledAt),
                        _buildTableCell(counterName),
                        _buildTableCell(staffName),
                        _buildTableCell(studentName),
                        _buildTableCell(studentEmail),
                      ],
                    );
                  }), // Removed .toList()
                ],
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'queue_history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = io.File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: Translations.translate('queue_history_export', _currentLanguage),
        subject: Translations.translate('history_pdf_export', _currentLanguage),
      );

      if (mounted) {
        _showSnackBar(
          '${Translations.translate('pdf_exported_successfully', _currentLanguage)}: $fileName', // Interpolated string
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '${Translations.translate('error_exporting_pdf', _currentLanguage)}: $e', // Interpolated string
          Colors.red,
        );
      }
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildHistoryCard(dynamic item) {
    final tokenNumber = item['tokenNumber']?.toString() ?? 'N/A';
    final serviceName = item['serviceId']?['serviceName'] ?? 'N/A';
    final queueName = item['queueId']?['queueName'] ?? 'N/A';
    final status = item['status'] ?? 'N/A';
    final generatedAt = item['generatedAt'] != null
        ? DateTime.parse(item['generatedAt'])
        : null;
    final completedAt = item['completedAt'] != null
        ? DateTime.parse(item['completedAt'])
        : null;
    final cancelledAt = item['cancelledAt'] != null
        ? DateTime.parse(item['cancelledAt'])
        : null;
    final counterName =
        item['counterId']?['counterName'] ?? 'N/A'; // Added counter name
    final staffName = item['staffId']?['name'] ?? 'N/A'; // Added staff name
    final studentName =
        item['studentId']?['name'] ?? 'N/A'; // Added student name
    final studentEmail =
        item['studentId']?['email'] ?? 'N/A'; // Added student email

    Color statusColor;
    IconData statusIcon; // Changed from io.IconData
    if (status.toString().toLowerCase() == 'completed' ||
        status.toString().toLowerCase() == 'served') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.toString().toLowerCase() == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info;
    }

    String eventTime = 'N/A';
    if (completedAt != null) {
      eventTime = DateFormat('MMM dd, yyyy HH:mm').format(completedAt);
    } else if (cancelledAt != null) {
      eventTime = DateFormat('MMM dd, yyyy HH:mm').format(cancelledAt);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${Translations.translate('token', _currentLanguage)} #$tokenNumber",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(
                      (255 * 0.1).round(),
                    ), // Changed from withOpacity
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        Translations.translate(
                          status.toLowerCase(),
                          _currentLanguage,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Translations.translate('service', _currentLanguage),
              serviceName,
              Icons.room_service,
            ),
            _buildInfoRow(
              Translations.translate('queue', _currentLanguage),
              queueName,
              Icons.queue,
            ),
            _buildInfoRow(
              Translations.translate('generated_at', _currentLanguage),
              generatedAt != null
                  ? DateFormat('MMM dd, yyyy HH:mm').format(generatedAt)
                  : 'N/A',
              Icons.timelapse,
            ),
            _buildInfoRow(
              Translations.translate(
                (status.toString().toLowerCase() == 'completed' ||
                        status.toString().toLowerCase() == 'served')
                    ? 'completed_at'
                    : 'cancelled_at',
                _currentLanguage,
              ),
              eventTime,
              Icons.event_note,
            ),
            _buildInfoRow(
              Translations.translate(
                'counter',
                _currentLanguage,
              ), // Added counter info
              counterName,
              Icons.store,
            ),
            _buildInfoRow(
              Translations.translate(
                'staff',
                _currentLanguage,
              ), // Added staff info
              staffName,
              Icons.person_pin,
            ),
            _buildInfoRow(
              Translations.translate(
                'student_name',
                _currentLanguage,
              ), // Added student name
              studentName,
              Icons.person,
            ),
            _buildInfoRow(
              Translations.translate(
                'student_email',
                _currentLanguage,
              ), // Added student email
              studentEmail,
              Icons.email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
