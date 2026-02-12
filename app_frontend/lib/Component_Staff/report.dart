// ignore_for_file: unused_field, dead_code, prefer_final_fields, deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/translations.dart';
import '../../services/api_config.dart';

class ReportScreen extends StatefulWidget {
  final String? adminId;
  final String? adminEmail;

  const ReportScreen({super.key, this.adminId, this.adminEmail});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  String _currentLanguage = 'english'; // Default

  // Report summary data
  int _totalTokensGenerated = 0;
  int _completedServicesToday = 0;
  int _totalStudentsVisited = 0;
  int _waitingStudents = 0;
  int _averageWaitingTimeMinutes = 0;

  List<dynamic> _dailyCrowd = [];
  List<dynamic> _serviceData = [];
  List<dynamic> _counterPerformance = [];
  List<dynamic> _busyHours = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (widget.adminId == null) return;
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchReportsSummary(),
      _fetchDailyCrowd(),
      _fetchServiceWise(),
      _fetchCounterPerformance(),
      _fetchBusyHours(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchReportsSummary() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/reports/summary/${widget.adminId}"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (mounted) {
            setState(() {
              _totalTokensGenerated = data['totalTokensGenerated'] ?? 0;
              _completedServicesToday = data['completedServicesToday'] ?? 0;
              _totalStudentsVisited = data['totalStudentsVisited'] ?? 0;
              _waitingStudents = data['waitingTokensCount'] ?? 0;
              _averageWaitingTimeMinutes = data['averageWaitingTimeMinutes'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching summary: $e");
    }
  }

  Future<void> _fetchDailyCrowd() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/admin/reports/daily-crowd/${widget.adminId}?days=7",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (mounted) {
             setState(() {
              _dailyCrowd = data['dailyCrowd'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching daily crowd: $e");
    }
  }

  Future<void> _fetchServiceWise() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/admin/reports/service-wise/${widget.adminId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (mounted) {
            setState(() {
              _serviceData = data['serviceData'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching service wise: $e");
    }
  }

  Future<void> _fetchCounterPerformance() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/admin/reports/counter-performance/${widget.adminId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (mounted) {
            setState(() {
              _counterPerformance = data['performance'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching counter performance: $e");
    }
  }

  Future<void> _fetchBusyHours() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/admin/reports/busy-hours/${widget.adminId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (mounted) {
            setState(() {
              _busyHours = data['busyHours'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching busy hours: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          Translations.translate('reports', _currentLanguage),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAllData),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    Translations.translate('daily_progress', _currentLanguage),
                  ),
                  const SizedBox(height: 12),
                  _buildLineChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Service-wise Distribution'),
                  const SizedBox(height: 12),
                  _buildPieChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Counter Performance'),
                  const SizedBox(height: 12),
                  _buildCounterBars(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  // Helper to build responsive summary grid
  Widget _buildSummaryGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 4 : 2;
    final childAspectRatio = width > 600 ? 1.5 : 1.3;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: childAspectRatio,
      children: [
        _summaryCard(
          Translations.translate('total_generated', _currentLanguage),
          _totalTokensGenerated.toString(),
          Icons.confirmation_number,
          Colors.blue,
        ),
        _summaryCard(
          Translations.translate('completed_today', _currentLanguage),
          _completedServicesToday.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _summaryCard(
          Translations.translate('students_visited', _currentLanguage),
          _totalStudentsVisited.toString(),
          Icons.people,
          Colors.orange,
        ),
        _summaryCard(
          Translations.translate('waiting_now', _currentLanguage),
          _waitingStudents.toString(),
          Icons.hourglass_top,
          Colors.red,
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_dailyCrowd.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No data available")),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 32, 32, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               _chartLegend("Generated", Colors.blue),
               const SizedBox(width: 12),
               _chartLegend("Served", Colors.green),
               const SizedBox(width: 12),
               _chartLegend("Pending", Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < _dailyCrowd.length) {
                          final dateStr = _dailyCrowd[idx]['_id']; // YYYY-MM-DD
                          final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Generated Line
                  LineChartBarData(
                    spots: _dailyCrowd.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value['generated'] ?? 0).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  // Served Line
                  LineChartBarData(
                    spots: _dailyCrowd.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value['served'] ?? 0).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  // Pending Line
                  LineChartBarData(
                    spots: _dailyCrowd.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value['pending'] ?? 0).toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildPieChart() {
    if (_serviceData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No data available")),
      );
    }

    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.redAccent,
      Colors.purple,
      Colors.cyan,
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _serviceData.asMap().entries.map((e) {
                  final color = colors[e.key % colors.length];
                  final count = e.value['count'] ?? 0;
                  // Calculate total for percentage if needed, but count is fine
                  return PieChartSectionData(
                    color: color,
                    value: count.toDouble(),
                    title: '$count',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: _Badge(
                      e.value['serviceName'] ?? 'Unknown',
                      size: 40,
                      borderColor: color,
                    ),
                    badgePositionPercentageOffset: 1.4,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Distribution by Service Type", 
             style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBars() {
    if (_counterPerformance.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No data available")),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTable(
            columnSpacing: 10, // Compress columns if needed
            headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade50),
            columns: const [
              DataColumn(label: Text('Counter', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Served', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Avg Time', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _counterPerformance.map((data) {
              return DataRow(cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      data['counterName'] ?? "N/A",
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ),
                DataCell(Text("${data['count'] ?? 0}")),
                DataCell(Text("${data['avgWaitTimeMinutes'] ?? 0} min")),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(this.text, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
