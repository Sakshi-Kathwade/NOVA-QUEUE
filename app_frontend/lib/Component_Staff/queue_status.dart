import 'package:flutter/material.dart';

class QueueStatusScreen extends StatelessWidget {
  const QueueStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Queue Status"),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Queue Info Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.queue, size: 28, color: Colors.deepPurple),
                        SizedBox(width: 12),
                        Text(
                          "Queue Name: Admin Counter 2",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.access_time, size: 28, color: Colors.orange),
                        SizedBox(width: 12),
                        Text(
                          "Timing: 10:00 AM - 5:00 PM",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_open,
                          size: 28,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Status: Open",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Toggle Open / Close action
                          },
                          icon: const Icon(Icons.sync_alt),
                          label: const Text("Toggle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              124,
                              56,
                              226,
                            ),
                            foregroundColor: const Color.fromRGBO(
                              248,
                              248,
                              249,
                              1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.person, size: 28, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          "Total Students: 25",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Sub-Info Cards (Optional detailed info)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _infoCard(
                  title: "Students Waiting",
                  value: "12",
                  icon: Icons.people,
                  color: Colors.orange,
                ),
                _infoCard(
                  title: "Current Token",
                  value: "A-07",
                  icon: Icons.confirmation_number,
                  color: Colors.blue,
                ),
                _infoCard(
                  title: "Completed Today",
                  value: "38",
                  icon: Icons.check_circle,
                  color: Colors.purple,
                ),
                _infoCard(
                  title: "Pending Today",
                  value: "5",
                  icon: Icons.pending_actions,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- Info Card Widget -------------------
  static Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
