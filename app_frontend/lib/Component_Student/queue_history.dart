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
      backgroundColor: Colors.grey.shade50,

      // 🔹 APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          "Queue History",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded),
            onPressed: _pickDate,
            tooltip: "Filter by date",
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                setState(() {
                  selectedDate = null;
                });
              },
              tooltip: "Clear filter",
            ),
        ],
      ),

      body: filteredHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No queue history found",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              // ✅ Limit items to prevent overloading on Android
              itemCount: filteredHistory.length > 50 ? 50 : filteredHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              // ✅ Use cacheExtent to optimize scrolling
              cacheExtent: 500,
              itemBuilder: (context, index) {
                final item = filteredHistory[index];
                final bool isCompleted = item["status"] == "Completed";

                return Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Optional: Add detail view
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // ✅ Status Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: isCompleted
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // ✅ Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["queueName"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Token: ${item["token"]}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy').format(item["date"]),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ✅ Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item["status"],
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
