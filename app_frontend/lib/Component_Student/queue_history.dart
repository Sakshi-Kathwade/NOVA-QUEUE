// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../services/language_service.dart';
import '../services/translations.dart';
import '../services/api_config.dart'; // Ensure you have this or use direct URL

class QueueHistoryScreen extends StatefulWidget {
  final String studentId;

  const QueueHistoryScreen({super.key, required this.studentId});

  @override
  State<QueueHistoryScreen> createState() => _QueueHistoryScreenState();
}

class _QueueHistoryScreenState extends State<QueueHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyData = [];
  String? _errorMsg;
  DateTime? _selectedDate;
  String _currentLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchHistory();
  }

  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage(widget.studentId);
    if (mounted) {
      setState(() {
        _currentLanguage = lang;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // Use localhost for emulator (10.0.2.2) or correct IP if device
      // Assuming web or windows for now based on context
      final uri = Uri.parse("http://localhost:8000/api/student/history/${widget.studentId}");
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["history"] != null) {
          final List<dynamic> raw = data["history"];
          setState(() {
            _historyData = raw.map<Map<String, dynamic>>((e) {
              return {
                "date": e["date"], // String from backend
                "queueName": e["queueName"] ?? "-",
                "tokenNumber": e["tokenNumber"] ?? 0,
                "department": e["department"] ?? "-",
                "purpose": e["purpose"] ?? "-",
                "waitingTimeMinutes": e["waitingTimeMinutes"] ?? 0,
                "status": e["status"] ?? "-",
                "studentsAhead": e["studentsAhead"] ?? 0,
              };
            }).toList();
          });
        }
      } else {
        setState(() => _errorMsg = "Failed to load history");
      }
    } catch (e) {
      setState(() => _errorMsg = "Unable to connect: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedDate == null) return _historyData;
    return _historyData.where((item) {
      final dStr = item["date"];
      if (dStr == null) return false;
      try {
        final d = DateTime.parse(dStr).toLocal();
        return d.year == _selectedDate!.year &&
            d.month == _selectedDate!.month &&
            d.day == _selectedDate!.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // --- EXPORT FUNCTIONS ---

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final data = _filteredHistory;

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
                    pw.Text("My Queue History",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text(_selectedDate != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                        : "All Records"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Date', 'Queue', 'Token', 'Department', 'Purpose', 'Status', 'Wait Time'],
                  ...data.map((item) {
                     final d = DateTime.parse(item["date"]).toLocal();
                     return [
                        DateFormat('yyyy-MM-dd HH:mm').format(d),
                        item['queueName'].toString(),
                        "A-${item['tokenNumber']}",
                        item['department'].toString(),
                        item['purpose'].toString(),
                        item['status'].toString(),
                        "${item['waitingTimeMinutes']} min"
                     ];
                  }),
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.center,
                  6: pw.Alignment.centerRight,
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
    var excelFile = Excel.createExcel();
    Sheet sheetObject = excelFile['QueueHistory'];
    
    List<String> headers = ['Date', 'Queue', 'Token', 'Department', 'Purpose', 'Status', 'Wait Time'];
    for(int i=0; i<headers.length; i++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(bold: true);
    }

    final data = _filteredHistory;
    for (int i = 0; i < data.length; i++) {
        var item = data[i];
        final d = DateTime.parse(item["date"]).toLocal();
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i+1)).value = TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(d));
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i+1)).value = TextCellValue(item['queueName'].toString());
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i+1)).value = TextCellValue("A-${item['tokenNumber']}");
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i+1)).value = TextCellValue(item['department'].toString());
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i+1)).value = TextCellValue(item['purpose'].toString());
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i+1)).value = TextCellValue(item['status'].toString());
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i+1)).value = IntCellValue(item['waitingTimeMinutes']);
    }

    var fileBytes = excelFile.save();
    if(fileBytes != null) {
       final directory = await getApplicationDocumentsDirectory();
       final file = File('${directory.path}/queue_history_${DateTime.now().millisecondsSinceEpoch}.xlsx');
       await file.writeAsBytes(fileBytes);
       await Share.shareXFiles([XFile(file.path)], text: 'Exported Excel History');
    }
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(['Date', 'Queue', 'Token', 'Department', 'Purpose', 'Status', 'Wait Time']);
    
    final data = _filteredHistory;
    for(var item in data) {
      final d = DateTime.parse(item["date"]).toLocal();
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(d),
        item['queueName'],
        "A-${item['tokenNumber']}",
        item['department'],
        item['purpose'],
        item['status'],
        "${item['waitingTimeMinutes']} min"
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/queue_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported CSV History');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(Translations.translate("queue_history", _currentLanguage)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
             icon: const Icon(Icons.refresh), 
             onPressed: _fetchHistory,
             tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Export Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    // Date Picker
                    Expanded(
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
                                _selectedDate == null 
                                  ? "Filter by Date" 
                                  : DateFormat('MMM d, yyyy').format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.grey : Colors.black,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              if (_selectedDate != null)
                                InkWell(
                                  onTap: () => setState(() => _selectedDate = null),
                                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                )
                              else
                                const Icon(Icons.calendar_today, size: 18, color: Colors.deepPurple),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Export Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _exportBtn(Icons.picture_as_pdf, Colors.red, "PDF", _exportToPdf),
                      const SizedBox(width: 10),
                      _exportBtn(Icons.table_chart, Colors.green, "Excel", _exportToExcel),
                      const SizedBox(width: 10),
                      _exportBtn(Icons.description, Colors.blue, "CSV", _exportToCsv),
                      const SizedBox(width: 10),
                      _exportBtn(Icons.print, Colors.black87, "Print", _exportToPdf), // Print uses PDF preview
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : _filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              "No history found",
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                           constraints: BoxConstraints(minWidth: width),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.grey.shade200,
                              ),
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade50),
                                columnSpacing: 24,
                                horizontalMargin: 24,
                                columns: const [
                                  DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Queue Name", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Token", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Department", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Purpose", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Wait Time", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _filteredHistory.map((item) {
                                  final d = DateTime.parse(item["date"]).toLocal();
                                  final status = item["status"].toString().toLowerCase();
                                  Color statusColor = Colors.grey;
                                  if (status == 'completed') statusColor = Colors.green;
                                  else if (status == 'cancelled') statusColor = Colors.red;
                                  else if (status == 'missed') statusColor = Colors.orange;
                                  else if (status == 'pending') statusColor = Colors.blue;

                                  return DataRow(cells: [
                                    DataCell(Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat('MMM dd').format(d), style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(DateFormat('HH:mm').format(d), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    )),
                                    DataCell(Text(item["queueName"].toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.deepPurple.shade200)
                                        ),
                                        child: Text(
                                          "A-${item["tokenNumber"]}",
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(item["department"].toString())),
                                    DataCell(ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150),child: Text(item["purpose"].toString(), overflow: TextOverflow.ellipsis))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: statusColor.withOpacity(0.3))
                                        ),
                                        child: Text(
                                          item["status"].toString().toUpperCase(),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text("${item["waitingTimeMinutes"]} min")),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _exportBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
