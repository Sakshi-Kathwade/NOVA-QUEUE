// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QueueHistoryScreen extends StatefulWidget {
  const QueueHistoryScreen({super.key});

  @override
  State<QueueHistoryScreen> createState() => _QueueHistoryScreenState();
}

class _QueueHistoryScreenState extends State<QueueHistoryScreen> {
  DateTime? selectedDate;

  // 🔹 SAMPLE DATA (Replace with API later)
  final List<Map<String, dynamic>> historyData = [
    {
      "date": DateTime(2025, 12, 20),
      "queueName": "Admission Queue",
      "token": "A-05",
      "status": "Completed",
    },
    {
      "date": DateTime(2025, 12, 22),
      "queueName": "Fee Payment",
      "token": "F-11",
      "status": "Cancelled",
    },
    {
      "date": DateTime(2025, 12, 24),
      "queueName": "Document Verification",
      "token": "D-03",
      "status": "Completed",
    },
  ];

  List<Map<String, dynamic>> get filteredHistory {
    if (selectedDate == null) {
      return historyData;
    }
    return historyData.where((item) {
      return item["date"].year == selectedDate!.year &&
          item["date"].month == selectedDate!.month &&
          item["date"].day == selectedDate!.day;
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text("Queue History"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: _pickDate),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  selectedDate = null;
                });
              },
            ),
        ],
      ),

      body: filteredHistory.isEmpty
          ? const Center(
              child: Text(
                "No queue history found",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final item = filteredHistory[index];
                final bool isCompleted = item["status"] == "Completed";

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted ? Colors.green : Colors.red,
                      child: Icon(
                        isCompleted ? Icons.check : Icons.close,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      item["queueName"],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          "Token: ${item["token"]}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Date: ${DateFormat('dd MMM yyyy').format(item["date"])}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        item["status"],
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: isCompleted ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
