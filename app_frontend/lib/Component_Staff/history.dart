// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, unnecessary_to_list_in_spreads

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  final String? adminId;
  final String? adminEmail;

  const HistoryScreen({super.key, this.adminId, this.adminEmail});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> historyData = [];
  List<Map<String, dynamic>> filteredData = [];

  // Filter states
  DateTime? startDate;
  DateTime? endDate;
  String selectedCategory = 'All';
  String selectedStatus = 'All';
  String searchQuery = '';

  // Activity categories
  final List<String> categories = [
    'All',
    'Login',
    'Logout',
    'Queue Management',
    'Token Operations',
    'User Management',
    'Settings',
    'System',
    'Transaction',
    'Error',
  ];

  // Status options
  final List<String> statuses = ['All', 'Success', 'Failed', 'Pending'];

  @override
  void initState() {
    super.initState();
    fetchHistoryData();
  }

  // Fetch history data from backend
  Future<void> fetchHistoryData() async {
    setState(() => isLoading = true);

    try {
      // For now, using mock data structure
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/history"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true && data["data"] != null) {
          setState(() {
            historyData = List<Map<String, dynamic>>.from(data["data"]);
            filteredData = historyData;
            isLoading = false;
          });
        } else {
          // Use mock data for demonstration
          _loadMockData();
        }
      } else {
        // Use mock data for demonstration
        _loadMockData();
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      // Use mock data for demonstration
      _loadMockData();
    }
  }

  // Mock data for demonstration
  void _loadMockData() {
    setState(() {
      historyData = [
        {
          "id": "1",
          "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
          "actionType": "Login",
          "module": "Authentication",
          "userIdentifier": widget.adminEmail ?? "admin@example.com",
          "status": "Success",
          "ipAddress": "192.168.1.100",
          "deviceInfo": "Windows 10, Chrome",
          "description": "Admin logged in successfully",
        },
        {
          "id": "2",
          "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
          "actionType": "Queue Management",
          "module": "Queue Operations",
          "userIdentifier": widget.adminEmail ?? "admin@example.com",
          "status": "Success",
          "ipAddress": "192.168.1.100",
          "deviceInfo": "Windows 10, Chrome",
          "description": "Created new queue: Admission Queue",
        },
        {
          "id": "3",
          "timestamp": DateTime.now().subtract(const Duration(hours: 1)),
          "actionType": "Token Operations",
          "module": "Token Management",
          "userIdentifier": widget.adminEmail ?? "admin@example.com",
          "status": "Success",
          "ipAddress": "192.168.1.100",
          "deviceInfo": "Windows 10, Chrome",
          "description": "Completed token A-101 for student: John Doe",
        },
        {
          "id": "4",
          "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
          "actionType": "Settings",
          "module": "Configuration",
          "userIdentifier": widget.adminEmail ?? "admin@example.com",
          "status": "Success",
          "ipAddress": "192.168.1.100",
          "deviceInfo": "Windows 10, Chrome",
          "description": "Updated system settings",
        },
        {
          "id": "5",
          "timestamp": DateTime.now().subtract(const Duration(hours: 3)),
          "actionType": "Error",
          "module": "System",
          "userIdentifier": "System",
          "status": "Failed",
          "ipAddress": "N/A",
          "deviceInfo": "Server",
          "description": "Database connection timeout",
        },
        {
          "id": "6",
          "timestamp": DateTime.now().subtract(const Duration(days: 1)),
          "actionType": "Transaction",
          "module": "Payment",
          "userIdentifier": widget.adminEmail ?? "admin@example.com",
          "status": "Success",
          "ipAddress": "192.168.1.100",
          "deviceInfo": "Windows 10, Chrome",
          "description": "Processed payment for token A-95",
        },
        {
          "id": "7",
          "timestamp": DateTime.now().subtract(
            const Duration(days: 1, hours: 2),
          ),
          "actionType": "User Management",
          "module": "Admin Operations",
          "userIdentifier": widget.adminEmail ?? "admin@example.com",
          "status": "Success",
          "ipAddress": "192.168.1.100",
          "deviceInfo": "Windows 10, Chrome",
          "description": "Updated student profile: ID-12345",
        },
        {
          "id": "8",
          "timestamp": DateTime.now().subtract(const Duration(days: 2)),
          "actionType": "Logout",
          "module": "Authentication",
          "userIdentifier": widget.adminEmail ?? "admin@example.com",
          "status": "Success",
          "ipAddress": "192.168.1.100",
          "deviceInfo": "Windows 10, Chrome",
          "description": "Admin logged out",
        },
      ];
      filteredData = historyData;
      isLoading = false;
    });
  }

  // Apply filters
  void _applyFilters() {
    setState(() {
      filteredData = historyData.where((item) {
        // Date range filter
        if (startDate != null || endDate != null) {
          final itemDate = item["timestamp"] as DateTime;
          if (startDate != null && itemDate.isBefore(startDate!)) return false;
          if (endDate != null &&
              itemDate.isAfter(endDate!.add(const Duration(days: 1))))
            return false;
        }

        // Category filter
        if (selectedCategory != 'All') {
          if (item["actionType"] != selectedCategory) return false;
        }

        // Status filter
        if (selectedStatus != 'All') {
          if (item["status"] != selectedStatus) return false;
        }

        // Search filter
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final description = (item["description"] ?? "")
              .toString()
              .toLowerCase();
          final module = (item["module"] ?? "").toString().toLowerCase();
          final user = (item["userIdentifier"] ?? "").toString().toLowerCase();
          if (!description.contains(query) &&
              !module.contains(query) &&
              !user.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  // Show date range picker
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _applyFilters();
    }
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      startDate = null;
      endDate = null;
      selectedCategory = 'All';
      selectedStatus = 'All';
      searchQuery = '';
    });
    _applyFilters();
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Success':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get action type icon
  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'Login':
        return Icons.login;
      case 'Logout':
        return Icons.logout;
      case 'Queue Management':
        return Icons.queue;
      case 'Token Operations':
        return Icons.confirmation_number;
      case 'User Management':
        return Icons.people;
      case 'Settings':
        return Icons.settings;
      case 'Transaction':
        return Icons.payment;
      case 'Error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  // Get action type color
  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'Login':
        return Colors.blue;
      case 'Logout':
        return Colors.grey;
      case 'Queue Management':
        return Colors.purple;
      case 'Token Operations':
        return Colors.orange;
      case 'User Management':
        return Colors.teal;
      case 'Settings':
        return Colors.deepPurple;
      case 'Transaction':
        return Colors.green;
      case 'Error':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Activity History"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: "Export",
            onSelected: (value) {
              if (value == 'csv') {
                _exportToCSV();
              } else if (value == 'pdf') {
                _exportToPDF();
              }
            },
            itemBuilder: (context) => [
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
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchHistoryData,
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

                // History List
                Expanded(
                  child: filteredData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No history records found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchHistoryData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filteredData.length,
                            itemBuilder: (context, index) {
                              return _buildHistoryCard(filteredData[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // Build filter section
  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  "Filters",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text("Clear All"),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search by description, module, or user...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
                _applyFilters();
              },
            ),

            const SizedBox(height: 8),

            // Category and Status dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value ?? 'All');
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedStatus = value ?? 'All');
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date range picker
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectDateRange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  minimumSize: const Size(0, 44),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        startDate != null && endDate != null
                            ? "${DateFormat('MMM dd').format(startDate!)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}"
                            : "Select Date Range",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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

  // Export to CSV
  Future<void> _exportToCSV() async {
    try {
      if (filteredData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No data to export"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create CSV content
      final csvBuffer = StringBuffer();
      // Header
      csvBuffer.writeln(
        'Timestamp,Action Type,Module,Status,User/Admin,IP Address,Device Info,Description',
      );

      // Data rows
      for (final item in filteredData) {
        final timestamp = item["timestamp"] as DateTime;
        csvBuffer.writeln(
          '"${DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp)}",'
          '"${item["actionType"] ?? "Unknown"}",'
          '"${item["module"] ?? "Unknown"}",'
          '"${item["status"] ?? "Unknown"}",'
          '"${item["userIdentifier"] ?? "Unknown"}",'
          '"${item["ipAddress"] ?? "N/A"}",'
          '"${item["deviceInfo"] ?? "N/A"}",'
          '"${(item["description"] ?? "No description").toString().replaceAll('"', '""')}"',
        );
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvBuffer.toString());

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Activity History Export',
        subject: 'History CSV Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("CSV exported successfully: $fileName"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error exporting CSV: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    try {
      if (filteredData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No data to export"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final pdf = pw.Document();

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Activity History Report',
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

              // Summary
              pw.Text(
                'Total Records: ${filteredData.length}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('Timestamp', isHeader: true),
                      _buildTableCell('Action Type', isHeader: true),
                      _buildTableCell('Module', isHeader: true),
                      _buildTableCell('Status', isHeader: true),
                      _buildTableCell('User/Admin', isHeader: true),
                      _buildTableCell('Description', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...filteredData.map((item) {
                    final timestamp = item["timestamp"] as DateTime;
                    return pw.TableRow(
                      children: [
                        _buildTableCell(
                          DateFormat('MMM dd, HH:mm').format(timestamp),
                        ),
                        _buildTableCell(item["actionType"] ?? "Unknown"),
                        _buildTableCell(item["module"] ?? "Unknown"),
                        _buildTableCell(item["status"] ?? "Unknown"),
                        _buildTableCell(item["userIdentifier"] ?? "Unknown"),
                        _buildTableCell(
                          item["description"] ?? "No description",
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Activity History Export',
        subject: 'History PDF Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF exported successfully: $fileName"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error exporting PDF: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper for PDF table cells
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

  // Build history card
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final timestamp = item["timestamp"] as DateTime;
    final actionType = item["actionType"] ?? "Unknown";
    final status = item["status"] ?? "Unknown";
    final description = item["description"] ?? "No description";
    final module = item["module"] ?? "Unknown";
    final userIdentifier = item["userIdentifier"] ?? "Unknown";

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showDetailsDialog(item),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Action icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getActionColor(actionType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getActionIcon(actionType),
                      color: _getActionColor(actionType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action type and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actionType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              module,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Timestamp
                  Text(
                    DateFormat('MMM dd, HH:mm').format(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(description, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              // User and time info
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      userIdentifier,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm:ss').format(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show details dialog
  void _showDetailsDialog(Map<String, dynamic> item) {
    final timestamp = item["timestamp"] as DateTime;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getActionIcon(item["actionType"] ?? "Unknown"),
              color: _getActionColor(item["actionType"] ?? "Unknown"),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item["actionType"] ?? "Unknown",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow("Module", item["module"] ?? "Unknown"),
              _detailRow("Status", item["status"] ?? "Unknown"),
              _detailRow(
                "Description",
                item["description"] ?? "No description",
              ),
              _detailRow("User/Admin", item["userIdentifier"] ?? "Unknown"),
              _detailRow("IP Address", item["ipAddress"] ?? "N/A"),
              _detailRow("Device Info", item["deviceInfo"] ?? "N/A"),
              _detailRow(
                "Timestamp",
                DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp),
              ),
            ],
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

  // Detail row widget
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
