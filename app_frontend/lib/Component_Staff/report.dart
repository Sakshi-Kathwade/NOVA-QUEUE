import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // 🔹 Selected date for filtering
  DateTime selectedDate = DateTime.now();

  // 🔹 Queue History Data (Dummy – API ready)
  final List<Map<String, dynamic>> queueHistory = [
    {
      "token": 101,
      "name": "Amit Sharma",
      "purpose": "Fee Enquiry",
      "date": DateTime.now(),
    },
    {
      "token": 102,
      "name": "Sakshi Patil",
      "purpose": "Document Verification",
      "date": DateTime.now(),
    },
    {
      "token": 103,
      "name": "Rahul Verma",
      "purpose": "Admission Query",
      "date": DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  // 🔹 Filtered data based on date
  List<Map<String, dynamic>> get filteredHistory {
    return queueHistory.where((item) {
      DateTime d = item["date"];
      return d.day == selectedDate.day &&
          d.month == selectedDate.month &&
          d.year == selectedDate.year;
    }).toList();
  }

  // 🔹 Pick date
  Future<void> selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Summary Card
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: "Students Served",
                    value: filteredHistory.length.toString(),
                    icon: Icons.people,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔹 Date Filter
            ElevatedButton.icon(
              onPressed: selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 30,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Queue History Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Queue History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 History List
            Expanded(
              child: filteredHistory.isEmpty
                  ? const Center(
                      child: Text(
                        "No records found for selected date",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredHistory.length,
                      itemBuilder: (context, index) {
                        final item = filteredHistory[index];

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                item["token"].toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              item["name"],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(item["purpose"]),
                            trailing: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Reusable Summary Card Widget
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
