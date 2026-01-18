// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class CompletedTodayScreen extends StatefulWidget {
  const CompletedTodayScreen({super.key});

  @override
  State<CompletedTodayScreen> createState() => _CompletedTodayScreenState();
}

class _CompletedTodayScreenState extends State<CompletedTodayScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> completedTokens = [];
  List<Map<String, dynamic>> filteredTokens = [];
  Timer? _refreshTimer;

  // Filter and search states
  String searchQuery = '';
  String sortBy = 'servedTime'; // 'servedTime', 'tokenNumber', 'studentName'
  bool sortAscending = false;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchCompletedTokens();
    // Real-time refresh every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchCompletedTokens();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Fetch completed tokens from backend
  Future<void> fetchCompletedTokens() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/completedtokens"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true && data["data"] != null) {
          setState(() {
            completedTokens = List<Map<String, dynamic>>.from(data["data"]);
            _applyFilters();
            isLoading = false;
          });
        } else {
          setState(() {
            completedTokens = [];
            filteredTokens = [];
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching completed tokens: $e");
      setState(() => isLoading = false);
    }
  }

  // Apply filters and sorting
  void _applyFilters() {
    setState(() {
      filteredTokens = List.from(completedTokens);

      // Date filter
      if (selectedDate != null) {
        filteredTokens = filteredTokens.where((token) {
          final servedTime = token["servedTime"] != null
              ? DateTime.parse(token["servedTime"])
              : null;
          if (servedTime == null) return false;
          return servedTime.year == selectedDate!.year &&
              servedTime.month == selectedDate!.month &&
              servedTime.day == selectedDate!.day;
        }).toList();
      }

      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filteredTokens = filteredTokens.where((token) {
          final tokenNumber = token["tokenNumber"]?.toString() ?? "";
          final studentName = (token["studentName"] ?? "").toLowerCase();
          final serviceProvided = (token["serviceProvided"] ?? "")
              .toLowerCase();
          final counterNumber = (token["counterNumber"] ?? "").toString();
          return tokenNumber.contains(query) ||
              studentName.contains(query) ||
              serviceProvided.contains(query) ||
              counterNumber.contains(query);
        }).toList();
      }

      // Sorting
      filteredTokens.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'tokenNumber':
            final aNum = a["tokenNumber"] ?? 0;
            final bNum = b["tokenNumber"] ?? 0;
            comparison = aNum.compareTo(bNum);
            break;
          case 'studentName':
            final aName = (a["studentName"] ?? "").toLowerCase();
            final bName = (b["studentName"] ?? "").toLowerCase();
            comparison = aName.compareTo(bName);
            break;
          case 'servedTime':
          default:
            final aTime = a["servedTime"] != null
                ? DateTime.parse(a["servedTime"])
                : DateTime(1970);
            final bTime = b["servedTime"] != null
                ? DateTime.parse(b["servedTime"])
                : DateTime(1970);
            comparison = aTime.compareTo(bTime);
            break;
        }
        return sortAscending ? comparison : -comparison;
      });
    });
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      selectedDate = null;
      sortBy = 'servedTime';
      sortAscending = false;
    });
    _applyFilters();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _applyFilters();
    }
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Completed Tokens Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
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
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Token',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Student Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Service',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Counter',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Served Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...filteredTokens.map((token) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            token["tokenNumber"]?.toString() ?? "N/A",
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(token["studentName"] ?? "N/A"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(token["serviceProvided"] ?? "N/A"),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            token["counterNumber"]?.toString() ?? "N/A",
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            token["servedTime"] != null
                                ? DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(DateTime.parse(token["servedTime"]))
                                : "N/A",
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
        "${output.path}/completed_tokens_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Completed Tokens Report');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error exporting PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export to CSV
  Future<void> _exportToCSV() async {
    try {
      final List<List<dynamic>> csvData = [
        [
          'Token Number',
          'Student Name',
          'Service Provided',
          'Counter Number',
          'Served Time',
        ],
        ...filteredTokens.map((token) {
          return [
            token["tokenNumber"]?.toString() ?? "N/A",
            token["studentName"] ?? "N/A",
            token["serviceProvided"] ?? "N/A",
            token["counterNumber"]?.toString() ?? "N/A",
            token["servedTime"] != null
                ? DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(DateTime.parse(token["servedTime"]))
                : "N/A",
          ];
        }),
      ];

      // Convert to CSV string manually
      final csvString = csvData.map((row) => row.join(',')).join('\n');
      final output = await getTemporaryDirectory();
      final file = File(
        "${output.path}/completed_tokens_${DateTime.now().millisecondsSinceEpoch}.csv",
      );
      await file.writeAsString(csvString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Completed Tokens Report');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error exporting CSV: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export to Excel (as CSV with .xlsx extension)
  Future<void> _exportToExcel() async {
    await _exportToCSV(); // For now, using CSV format
  }

  // Print functionality
  Future<void> _printReport() async {
    // For mobile, we'll export as PDF which can be printed
    await _exportToPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          "Completed Today",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded),
            tooltip: "Export",
            onSelected: (value) {
              if (value == 'pdf') {
                _exportToPDF();
              } else if (value == 'csv') {
                _exportToCSV();
              } else if (value == 'excel') {
                _exportToExcel();
              } else if (value == 'print') {
                _printReport();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_view, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export as Excel'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Print'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: fetchCompletedTokens,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Section
                _buildFilterSection(),

                // Stats Card
                _buildStatsCard(),

                // Tokens List
                Expanded(
                  child: filteredTokens.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No completed tokens found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchCompletedTokens,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTokens.length > 100
                                ? 100
                                : filteredTokens.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            cacheExtent: 500,
                            itemBuilder: (context, index) {
                              final token = filteredTokens[index];
                              return _buildTokenCard(token);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: Colors.deepPurple.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Filters & Search",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text("Clear"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search by token, name, service, or counter...",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() => searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
                _applyFilters();
              },
            ),
            const SizedBox(height: 12),
            // Date filter and Sort
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      selectedDate != null
                          ? DateFormat('dd MMM yyyy').format(selectedDate!)
                          : "Filter by Date",
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sortBy,
                    decoration: InputDecoration(
                      labelText: "Sort by",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'servedTime',
                        child: Text('Served Time'),
                      ),
                      DropdownMenuItem(
                        value: 'tokenNumber',
                        child: Text('Token Number'),
                      ),
                      DropdownMenuItem(
                        value: 'studentName',
                        child: Text('Student Name'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => sortBy = value ?? 'servedTime');
                      _applyFilters();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    setState(() => sortAscending = !sortAscending);
                    _applyFilters();
                  },
                  tooltip: "Toggle sort order",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade700,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Completed Today",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${filteredTokens.length}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard(Map<String, dynamic> token) {
    final servedTime = token["servedTime"] != null
        ? DateTime.parse(token["servedTime"])
        : null;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Optional: Show details dialog
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Token Number Badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "A-${token["tokenNumber"] ?? "N/A"}",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token["studentName"] ?? "Unknown",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.description_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            token["serviceProvided"] ?? "N/A",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.countertops_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Counter: ${token["counterNumber"] ?? "N/A"}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            servedTime != null
                                ? DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format(servedTime)
                                : "N/A",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
