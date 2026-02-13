// ignore_for_file: prefer_final_fields, unused_field, deprecated_member_use, use_build_context_synchronously, unnecessary_underscores, unnecessary_to_list_in_spreads, curly_braces_in_flow_control_structures, sort_child_properties_last

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/api_config.dart';

class AdminHistoryScreen extends StatefulWidget {
  final String? queueName;
  final String? adminId;

  const AdminHistoryScreen({super.key, this.queueName, this.adminId});

  @override
  _AdminHistoryScreenState createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  // Data
  List<dynamic> _historyTokens = [];
  Map<String, dynamic> _summary = {};
  
  // Calendar Data
  List<DateTime> _historyDates = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  // Form Filters
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedServiceId;
  String _selectedStatus = "All"; // Default
  String _currentReportType = "Daily";

  // UI State
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistoryDates(); // Fetch dates for calendar
    _fetchHistory();      // Fetch initial data (Today)
  }

  // Fetch Dates for Calendar Highlights
  Future<void> _fetchHistoryDates() async {
    if (widget.adminId == null) return;
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/history-dates/${widget.adminId}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final dates = (data['dates'] as List).map((d) {
             return DateTime.parse(d);
          }).toList();
          setState(() {
            _historyDates = dates;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching history dates: $e");
    }
  }

  // Main Fetch Function
  Future<void> _fetchHistory() async {
    if (widget.adminId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = <String, String>{};

      // Handle Date Filters
      DateTime start = _selectedDate;
      DateTime end = _selectedDate;

      if (_currentReportType == 'Daily') {
         // Already single day
      } else if (_currentReportType == 'Weekly') {
         // Find start of week (Monday = 1)
         start = start.subtract(Duration(days: start.weekday - 1));
         end = start.add(const Duration(days: 6));
      } else if (_currentReportType == 'Monthly') {
         start = DateTime(start.year, start.month, 1);
         end = DateTime(start.year, start.month + 1, 0);
      } else if (_currentReportType == 'Yearly') {
         start = DateTime(start.year, 1, 1);
         end = DateTime(start.year, 12, 31);
      }

      queryParams['startDate'] = start.toIso8601String();
      queryParams['endDate'] = end.toIso8601String();

      if (_selectedServiceId != null && _selectedServiceId != 'All') {
        queryParams['serviceId'] = _selectedServiceId!;
      }

      if (_selectedStatus != "All") {
        queryParams['status'] = _selectedStatus;
      }

      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }

      final uri = Uri.parse(
        "${ApiConfig.baseUrl}/admin/history/${widget.adminId}",
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            _historyTokens = jsonData['history'] ?? [];
            _summary = jsonData['summary'] ?? {};
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = jsonData['message'] ?? "Failed to load history";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection Error: $e";
        _isLoading = false;
      });
    }
  }

  // Delete Token
  Future<void> _deleteToken(String tokenId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/admin/history-token/$tokenId"),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record deleted successfully")),
        );
        _fetchHistory(); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
    }
  }

  void _confirmDelete(String tokenId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteToken(tokenId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // PDF Export
  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "$_currentReportType Report",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Generated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}",
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfSummaryItem("Total", "${_summary['totalTokens'] ?? 0}"),
                  _pdfSummaryItem("Served", "${_summary['totalServed'] ?? 0}"),
                  _pdfSummaryItem("Pending", "${_summary['pendingTokens'] ?? 0}"),
                  _pdfSummaryItem("Avg Wait", "${_summary['averageWaitingTimeMinutes'] ?? 0}m"),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Token', 'Student', 'Service', 'Counter', 'Status', 'Wait'],
                data: _historyTokens.map((token) {
                  String waitTime = "-";
                  if (token['generatedAt'] != null && token['completedAt'] != null) {
                    final gen = DateTime.parse(token['generatedAt']);
                    final comp = DateTime.parse(token['completedAt']);
                    final diff = comp.difference(gen).inMinutes;
                    waitTime = "${diff}m";
                  }
                  return [
                    DateFormat('yyyy-MM-dd').format(DateTime.parse(token['generatedAt']).toLocal()),
                    "A-${token['tokenNumber']}",
                    token['student']?['name'] ?? 'Guest',
                    token['service']?['serviceName'] ?? 'General',
                    token['counter']?['counterName'] ?? '-',
                    token['status'],
                    waitTime,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: PdfColors.deepPurple),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _pdfSummaryItem(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  void _onReportTypeChanged(String type) {
      setState(() {
          _currentReportType = type;
      });
      _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("History & Reports"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
           // CALENDAR SECTION
           Container(
             color: Colors.white,
             padding: const EdgeInsets.only(bottom: 8),
             child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2130, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                  CalendarFormat.week: 'Week',
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                    _currentReportType = 'Daily'; // Reset to daily on explicit select
                  });
                  _fetchHistory();
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                    for (var d in _historyDates) {
                        if (isSameDay(d, day)) return [true];
                    }
                    return [];
                },
                calendarStyle: const CalendarStyle(
                   markerDecoration: BoxDecoration(
                       color: Colors.deepPurple,
                       shape: BoxShape.circle,
                   ),
                   todayDecoration: BoxDecoration(
                       color: Colors.purpleAccent,
                       shape: BoxShape.circle,
                   ),
                   selectedDecoration: BoxDecoration(
                       color: Colors.deepPurple,
                       shape: BoxShape.circle,
                   ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
             ),
           ),

          const SizedBox(height: 10),

          // REPORT GENERATION & FILTERS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  const Text("Report Generation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                         _reportChip("Daily"),
                         const SizedBox(width: 8),
                         _reportChip("Weekly"),
                         const SizedBox(width: 8),
                         _reportChip("Monthly"),
                         const SizedBox(width: 8),
                         _reportChip("Yearly"),
                      ],
                  )),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // FILTERS ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: const [
                           DropdownMenuItem(value: "All", child: Text("All Status")),
                           DropdownMenuItem(value: "Completed", child: Text("Completed")),
                           DropdownMenuItem(value: "Pending", child: Text("Pending")),
                           DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
                        ],
                        onChanged: (val) {
                            setState(() => _selectedStatus = val!);
                            _fetchHistory();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                       labelText: "Search",
                       filled: true,
                       fillColor: Colors.white,
                       suffixIcon: IconButton(
                           icon: const Icon(Icons.search),
                           onPressed: _fetchHistory,
                       ),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _fetchHistory(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // RESULTS TABLE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyTokens.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text("No records found", style: TextStyle(color: Colors.grey.shade600))
                      ],
                    ))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade50),
                          columns: const [
                             DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                             DataColumn(label: Text("Token", style: TextStyle(fontWeight: FontWeight.bold))),
                             DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                             DataColumn(label: Text("Service", style: TextStyle(fontWeight: FontWeight.bold))),
                             DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                             DataColumn(label: Text("Wait", style: TextStyle(fontWeight: FontWeight.bold))),
                             DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _historyTokens.map((token) {
                             return DataRow(cells: [
                                DataCell(Text(DateFormat('dd-MM HH:mm').format(DateTime.parse(token['generatedAt']).toLocal()))),
                                DataCell(Text("A-${token['tokenNumber']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple))),
                                DataCell(Text(token['student']?['name'] ?? 'Guest')),
                                DataCell(Text(token['service']?['serviceName'] ?? 'General')),
                                DataCell(_statusBadge(token['status'])),
                                DataCell(Text(_calculateWait(token))),
                                DataCell(
                                    IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _confirmDelete(token['_id'])
                                    )
                                ),
                             ]);
                          }).toList(),
                        ),
                      ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _historyTokens.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: _exportToPdf,
            label: const Text("Export Report"),
            icon: const Icon(Icons.picture_as_pdf),
            backgroundColor: Colors.deepPurple,
          )
        : null,
    );
  }

  Widget _reportChip(String type) {
     final isSelected = _currentReportType == type;
     return ChoiceChip(
       label: Text(type),
       selected: isSelected,
       onSelected: (selected) {
          if (selected) _onReportTypeChanged(type);
       },
       selectedColor: Colors.deepPurple,
       backgroundColor: Colors.grey.shade200,
       labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
       ),
     );
  }

  Widget _statusBadge(String status) {
     Color color = Colors.grey;
     String s = status.toLowerCase();
     if (s == 'completed') color = Colors.green;
     else if (s.contains('pending') || s.contains('waiting') || s.contains('hold')) color = Colors.orange;
     else if (s == 'cancelled') color = Colors.red;

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
           color: color.withOpacity(0.1), 
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: color.withOpacity(0.5))
       ),
       child: Text(
           status.toUpperCase(), 
           style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)
       ),
     );
  }

  String _calculateWait(dynamic token) {
      if (token['generatedAt'] != null && token['completedAt'] != null) {
          final gen = DateTime.parse(token['generatedAt']);
          final comp = DateTime.parse(token['completedAt']);
          final diff = comp.difference(gen).inMinutes;
          return "${diff}m";
      }
      return "-";
  }
}
