import 'package:flutter/material.dart';

class CompletedTodayScreen extends StatelessWidget {
  const CompletedTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final completedCount = 38;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Completed Today"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -------- TOTAL COMPLETED CARD --------
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Completed Tokens",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$completedCount",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -------- SIMPLE GRAPH --------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hourly Progress",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _hourBar("10–11 AM", 5),
                    _hourBar("11–12 PM", 8),
                    _hourBar("12–1 PM", 6),
                    _hourBar("2–3 PM", 10),
                    _hourBar("3–4 PM", 9),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- GRAPH BAR WIDGET --------
  static Widget _hourBar(String time, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(time)),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 10,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 8),
          Text("$value"),
        ],
      ),
    );
  }
}
