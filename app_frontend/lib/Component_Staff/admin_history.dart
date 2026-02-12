// ignore_for_file: prefer_final_fields, unused_field, deprecated_member_use, use_build_context_synchronously, unnecessary_underscores, unnecessary_to_list_in_spreads, curly_braces_in_flow_control_structures, sort_child_properties_last

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  // Form Filters
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedServiceId;
  String _selectedStatus = "All"; // Default

  // Dropdown Data
  List<dynamic> _services = [];

  // UI State
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    // Pre-fill today's date but do NOT auto-fetch unless requested?
    // User requested "when we click search". So initial state can be empty or today's data.
    // I will load today's data initially as a good UX practice, but make the search explicit for changes.
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    _fetchHistory();
  }

  Future<void> _fetchDropdownData() async {
    if (widget.adminId == null) return;
    try {
      final serviceRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/services/${widget.adminId}"),
      );
      if (serviceRes.statusCode == 200) {
        setState(() {
          _services = json.decode(serviceRes.body)['services'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching dropdown data: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _fetchHistory() async {
    if (widget.adminId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final queryParams = <String, String>{};

      if (_selectedDate != null) {
        queryParams['startDate'] = _selectedDate!.toIso8601String();
        queryParams['endDate'] = _selectedDate!.toIso8601String();
      }

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

  Future<void> _deleteToken(String tokenId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/admin/history-token/$tokenId"),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record deleted successfully")),
        );
        _fetchHistory();
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
                      "Queue History Report",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Date: ${_dateController.text}",
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
                  _pdfSummaryItem(
                    "Pending",
                    "${_summary['pendingTokens'] ?? 0}",
                  ),
                  _pdfSummaryItem(
                    "Avg Wait",
                    "${_summary['averageWaitingTimeMinutes'] ?? 0}m",
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Date',
                  'Queue',
                  'Service',
                  'Student',
                  'Token',
                  'Counter',
                  'Status',
                  'Wait',
                ],
                data: _historyTokens.map((token) {
                  String waitTime = "-";
                  if (token['generatedAt'] != null &&
                      token['completedAt'] != null) {
                    final gen = DateTime.parse(token['generatedAt']);
                    final comp = DateTime.parse(token['completedAt']);
                    final diff = comp.difference(gen).inMinutes;
                    waitTime = "${diff}m";
                  }
                  return [
                    DateFormat('yyyy-MM-dd').format(DateTime.parse(token['generatedAt']).toLocal()),
                    token['queue']?['queueName'] ?? token['queueName'] ?? 'Deleted Queue',
                    token['service']?['serviceName'] ?? token['serviceName'] ?? token['department'] ?? 'General',
                    token['student']?['name'] ?? 'Unknown',
                    "A-${token['tokenNumber']}",
                    token['counter']?['counterName'] ?? '-',
                    token['status'],
                    waitTime,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
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
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
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
          // 1. FILTER SECTION (Form)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: Date & Service
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          labelText: "Select Date",
                          hintText: "YYYY-MM-DD",
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.deepPurple,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedServiceId,
                            hint: const Text("Service"),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("All Services"),
                              ),
                              ..._services.map(
                                (s) => DropdownMenuItem(
                                  value: s['_id'].toString(),
                                  child: Text(s['serviceName']),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedServiceId = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 2: Status & Search Button
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: "All",
                                child: Text("All Status"),
                              ),
                              DropdownMenuItem(
                                value: "Completed",
                                child: Text("Completed"),
                              ),
                              DropdownMenuItem(
                                value: "Pending",
                                child: Text("Pending"),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedStatus = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: "Search (Optional)",
                          hintText: "Name or Token",
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Button
                ElevatedButton.icon(
                  onPressed: _fetchHistory,
                  icon: const Icon(Icons.search),
                  label: const Text("Search History"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. Summary Cards
          if (_historyTokens.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      "Tokens",
                      "${_summary['totalTokens'] ?? 0}",
                      Icons.confirmation_number,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      "Pending",
                      "${_summary['pendingTokens'] ?? 0}",
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      "Avg Wait",
                      "${_summary['averageWaitingTimeMinutes'] ?? 0}m",
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

          // 3. Results Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _historyTokens.isEmpty
                ? _buildEmptyState()
                : _buildHistoryTable(),
          ),
        ],
      ),
      floatingActionButton: _historyTokens.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,

              child: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _exportToPdf,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No data available for this date",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please create a queue or adjust your filters.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              Colors.deepPurple.withOpacity(0.05),
            ),
            columnSpacing: 20,
            horizontalMargin: 12,
            border: TableBorder(borderRadius: BorderRadius.circular(8)),
            columns: const [
              DataColumn(
                label: Text(
                  'Time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Token',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Student',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Service',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: _historyTokens.map((token) {
              final status = token['status'] ?? 'Unknown';
              Color statusColor = Colors.grey;
              if (status.toLowerCase().contains('completed'))
                statusColor = Colors.green;
              else if (status.toLowerCase().contains('pending') ||
                  status.toLowerCase().contains('waiting'))
                statusColor = Colors.orange;

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      DateFormat(
                        'HH:mm',
                      ).format(DateTime.parse(token['generatedAt']).toLocal()),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "A-${token['tokenNumber']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(token['student']?['name'] ?? 'Guest')),
                  DataCell(Text(token['service']?['serviceName'] ?? 'General')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _confirmDelete(token['_id']),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
