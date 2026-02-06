// ignore_for_file: unused_field, dead_code, prefer_final_fields, deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/translations.dart';

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
        Uri.parse(
          "http://localhost:8000/api/admin/reports/summary/${widget.adminId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _totalTokensGenerated = data['totalTokensGenerated'] ?? 0;
            _completedServicesToday = data['completedServicesToday'] ?? 0;
            _totalStudentsVisited = data['totalStudentsVisited'] ?? 0;
            _waitingStudents = data['waitingTokensCount'] ?? 0;
            _averageWaitingTimeMinutes = data['averageWaitingTimeMinutes'] ?? 0;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchDailyCrowd() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/admin/reports/daily-crowd/${widget.adminId}?days=7",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _dailyCrowd = data['dailyCrowd'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchServiceWise() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/admin/reports/service-wise/${widget.adminId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _serviceData = data['serviceData'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchCounterPerformance() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/admin/reports/counter-performance/${widget.adminId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _counterPerformance = data['performance'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchBusyHours() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:8000/api/admin/reports/busy-hours/${widget.adminId}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _busyHours = data['busyHours'];
          });
        }
      }
    } catch (e) {
      print(e);
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

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _summaryCard(
          'Total Generated',
          _totalTokensGenerated.toString(),
          Icons.confirmation_number,
          Colors.blue,
        ),
        _summaryCard(
          'Completed Today',
          _completedServicesToday.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _summaryCard(
          'Students Visited',
          _totalStudentsVisited.toString(),
          Icons.people,
          Colors.orange,
        ),
        _summaryCard(
          'Waiting Now',
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
    if (_dailyCrowd.isEmpty)
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No data available")),
      );

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 32, 32, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < _dailyCrowd.length) {
                    final date = DateTime.parse(_dailyCrowd[idx]['_id']);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: const TextStyle(fontSize: 10),
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
            LineChartBarData(
              spots: _dailyCrowd
                  .asMap()
                  .entries
                  .map(
                    (e) =>
                        FlSpot(e.key.toDouble(), e.value['count'].toDouble()),
                  )
                  .toList(),
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.deepPurple.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_serviceData.isEmpty)
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No data available")),
      );

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.cyan,
    ];

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: _serviceData.asMap().entries.map((e) {
            final color = colors[e.key % colors.length];
            return PieChartSectionData(
              color: color,
              value: e.value['count'].toDouble(),
              title: '${e.value['count']}',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              badgeWidget: _Badge(
                e.value['serviceName'],
                size: 40,
                borderColor: color,
              ),
              badgePositionPercentageOffset: 1.3,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCounterBars() {
    if (_counterPerformance.isEmpty)
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No data available")),
      );

    return Column(
      children: _counterPerformance.map((data) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.computer, color: Colors.white, size: 20),
            ),
            title: Text(
              data['counterName'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${data['count']} Done",
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
