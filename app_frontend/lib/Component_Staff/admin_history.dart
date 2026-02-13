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
  
  String _selectedService = "All"; 
  List<String> _serviceOptions = ["All", "Exam", "Admission", "Fees", "General"];

  String _selectedStatus = "All";
  List<String> _statusOptions = ["All", "Completed", "Pending", "Cancelled"];

  // UI State
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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

      if (_selectedService != "All") {
         queryParams['counterId'] = _selectedService; 
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
                        item['service']?['serviceName'] ?? '-',
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

        sheetObject.cell(excel_pkg.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i+1)).value = excel_pkg.TextCellValue(token['service']?['serviceName'] ?? '-');

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
        token['service']?['serviceName'] ?? '-',
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
                        flex: 1,
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
                      // Date Picker (Context aware based on frequency would be complex, keeping simple date input)
                      Expanded(
                        flex: 2,
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
                  
                  // FILTERS ROW
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          value: _selectedService, 
                          items: _serviceOptions, 
                          label: "Service",
                          onChanged: (val) => setState(() => _selectedService = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _fetchHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("GENERATE REPORT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
  
            const SizedBox(height: 16),
  
            // EXPORT ACTIONS (Visible if searched)
            if (_hasSearched && !_isLoading)
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
                        child: Text(
                          _hasSearched ? "No records found." : "Select filters to view data.",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                              columns: const [
                                DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Token', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Service', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Wait', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _historyTokens.map((token) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(DateFormat('MM/dd HH:mm').format(DateTime.parse(token['generatedAt']).toLocal()))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text("A-${token['tokenNumber']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                      ),
                                    ),
                                    DataCell(Text(token['student']?['name'] ?? 'Guest')),
                                    DataCell(Text(token['service']?['serviceName'] ?? '-')),
                                    DataCell(_statusBadge(token['status'])),
                                    DataCell(Text(_calculateWait(token))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                        onPressed: () => _confirmDelete(token['_id']),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required String label, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _exportBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        elevation: 1,
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    String s = status.toLowerCase();
    
    if (s == 'completed') color = Colors.green;
    else if (s.contains('pending')) color = Colors.orange;
    else if (s == 'cancelled') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
