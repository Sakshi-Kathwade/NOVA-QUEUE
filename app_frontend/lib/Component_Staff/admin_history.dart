// ignore_for_file: unused_field, deprecated_member_use, curly_braces_in_flow_control_structures, prefer_final_fields, use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  
  // Filters
  DateTime _selectedDate = DateTime.now();
  String _reportFrequency = "Daily"; // Daily, Weekly, Monthly, Yearly
  final List<String> _frequencyOptions = ["Daily", "Weekly", "Monthly", "Yearly"];
  
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCounter = "All"; 
  // Options explicitly requested by user + General fallback
  final List<String> _counterOptions = ["All", "Exam", "Admission", "Fees", "General"];

  String _selectedStatus = "All";
  final List<String> _statusOptions = ["All", "Completed", "Pending", "Cancelled"];

  // UI State
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  // Pick Date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Calculate Date Range based on Frequency
  Map<String, DateTime> _calculateDateRange() {
    DateTime start = _selectedDate;
    DateTime end = _selectedDate;

    switch (_reportFrequency) {
      case "Daily":
        start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
        end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
        break;
      case "Weekly":
        // Find Monday of the current week
        int daysToSubtract = _selectedDate.weekday - 1;
        start = _selectedDate.subtract(Duration(days: daysToSubtract));
        // Reset time
        start = DateTime(start.year, start.month, start.day, 0, 0, 0);
        
        // End is Sunday
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case "Monthly":
        start = DateTime(_selectedDate.year, _selectedDate.month, 1, 0, 0, 0);
        // Last day of month
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
        break;
      case "Yearly":
        start = DateTime(_selectedDate.year, 1, 1, 0, 0, 0);
        end = DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
        break;
    }
    return {'start': start, 'end': end};
  }

  // Main Fetch Function
  Future<void> _fetchHistory() async {
    if (widget.adminId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final queryParams = <String, String>{};

      final range = _calculateDateRange();
      queryParams['startDate'] = range['start']!.toIso8601String();
      queryParams['endDate'] = range['end']!.toIso8601String();

      // Passing selected counter as counterId. 
      // Backend is updated to check Service Name if Counter Name not found.
      if (_selectedCounter != "All") {
         queryParams['counterId'] = _selectedCounter; 
      }

      if (_selectedStatus != "All") {
        queryParams['status'] = _selectedStatus.toLowerCase();
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
        _fetchHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Failed to delete record")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Error: $e")),
      );
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

  // --- EXPORT FUNCTIONS ---

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final range = _calculateDateRange();
    final dateStr = "${DateFormat('yyyy-MM-dd').format(range['start']!)} to ${DateFormat('yyyy-MM-dd').format(range['end']!)}";

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
                    pw.Text("SmartQ $_reportFrequency Report", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text(dateStr),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Date', 'Token', 'Name', 'Service', 'Status', 'Wait Time'],
                  ..._historyTokens.map((item) => [
                        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(item['generatedAt']).toLocal()),
                        "A-${item['tokenNumber']}",
                        item['student']?['name'] ?? 'Guest',
                        "${item['department'] ?? item['service']?['serviceName'] ?? '-'} ${item['counter'] != null ? '(${item['counter']['counterName']})' : ''}",
                        item['status'],
                        _calculateWait(item)
                      ]),
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _exportToExcel() async {
    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet sheetObject = excel['Report'];
    
    List<String> headers = ['Date', 'Token', 'Name', 'Service', 'Status', 'Wait Time'];
    for(int i=0; i<headers.length; i++) {
        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = excel_pkg.TextCellValue(headers[i]);

    }

    for (int i = 0; i < _historyTokens.length; i++) {
        var token = _historyTokens[i];
        
        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i+1)).value = excel_pkg.TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(token['generatedAt']).toLocal()));

        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i+1)).value = excel_pkg.TextCellValue("A-${token['tokenNumber']}");

        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i+1)).value = excel_pkg.TextCellValue(token['student']?['name'] ?? 'Guest');

        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i+1)).value = excel_pkg.TextCellValue("${token['department'] ?? token['service']?['serviceName'] ?? '-'} ${token['counter'] != null ? '(${token['counter']['counterName']})' : ''}");

        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i+1)).value = excel_pkg.TextCellValue(token['status']);
        
        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i+1)).value = excel_pkg.TextCellValue(_calculateWait(token));
    }

    var fileBytes = excel.save();
    if(fileBytes != null) {
       final directory = await getApplicationDocumentsDirectory();
       final file = File('${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
       await file.writeAsBytes(fileBytes);
       await Share.shareXFiles([XFile(file.path)], text: 'Exported Excel Report');
    }
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(['Date', 'Token', 'Name', 'Service', 'Status', 'Wait Time']);
    for(var token in _historyTokens) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(token['generatedAt']).toLocal()),
        "A-${token['tokenNumber']}",
        token['student']?['name'] ?? 'Guest',
        "${token['department'] ?? token['service']?['serviceName'] ?? '-'} ${token['counter'] != null ? '(${token['counter']['counterName']})' : ''}",
        token['status'],
        _calculateWait(token)
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported CSV Report');
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


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("History & Reports"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TOP CONTROLS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Report Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
                  const SizedBox(height: 10),
                  
                  // FREQUENCY & DATE ROW
                  Row(
                    children: [
                      // Frequency Dropdown
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _reportFrequency,
                              isExpanded: true,
                              items: _frequencyOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) => setState(() => _reportFrequency = val!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Date Picker
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM d, yyyy').format(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.calendar_month, color: Colors.deepPurple, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // FILTERS ROW (Status & Counter)
                  Row(
                    children: [
                      // Counter Filter
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedCounter, 
                          items: _counterOptions, 
                          label: "Counter",
                          onChanged: (val) => setState(() => _selectedCounter = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Status Filter
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedStatus, 
                          items: _statusOptions, 
                          label: "Status",
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // SEARCH BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _fetchHistory,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text("SEARCH", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
  
            const SizedBox(height: 16),
  
            // EXPORT ACTIONS (Visible if searched)
            if (_hasSearched && !_isLoading && _historyTokens.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _exportBtn(Icons.picture_as_pdf, Colors.red, "Download PDF", _exportToPdf),
                      const SizedBox(width: 10),
                      _exportBtn(Icons.table_chart, Colors.green, "Excel Export", _exportToExcel),
                      const SizedBox(width: 10),
                      _exportBtn(Icons.description, Colors.blue, "CSV Export", _exportToCsv),
                      const SizedBox(width: 10),
                      _exportBtn(Icons.print, Colors.black87, "Print Report", _exportToPdf),
                    ],
                  ),
                ),
              ),
  
            // DATA TABLE
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _historyTokens.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasSearched ? Icons.search_off : Icons.filter_alt_outlined,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _hasSearched ? "No matching records found." : "Select filters and click Search to view history.",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: screenWidth - 32),
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                                  columnSpacing: isSmallScreen ? 20 : 50,
                                  dataRowHeight: 60,
                                  columns: const [
                                    DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Token', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Service / Counter', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Wait', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _historyTokens.map((token) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(DateFormat('MMM d, yyyy').format(DateTime.parse(token['generatedAt']).toLocal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text(DateFormat('hh:mm a').format(DateTime.parse(token['generatedAt']).toLocal()), style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                            ],
                                          )
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.deepPurple.shade200)
                                            ),
                                            child: Text("A-${token['tokenNumber']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                          ),
                                        ),
                                        DataCell(Text(token['student']?['name'] ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.w500))),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(token['department'] ?? token['service']?['serviceName'] ?? token['purpose'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              if (token['counter'] != null)
                                                Text("Counter: ${token['counter']['counterName']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                            ],
                                          )
                                        ),
                                        DataCell(_statusBadge(token['status'])),
                                        DataCell(Text(_calculateWait(token), style: TextStyle(color: Colors.grey.shade800))),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                                            onPressed: () => _confirmDelete(token['_id']),
                                            tooltip: "Delete Record",
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required String label, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(label),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _exportBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade700;
    String s = status.toLowerCase();
    
    if (s == 'completed') {
      bg = Colors.green.shade50;
      text = Colors.green.shade700;
    } else if (s.contains('pending') || s == 'waiting' || s == 'process') {
      bg = Colors.orange.shade50;
      text = Colors.orange.shade800;
    } else if (s.contains('cancel') || s.contains('reject')) {
      bg = Colors.red.shade50;
      text = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.3))
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
