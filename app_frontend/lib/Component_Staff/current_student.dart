import 'package:flutter/material.dart';

class CurrentStudentScreen extends StatefulWidget {
  const CurrentStudentScreen({super.key});

  @override
  State<CurrentStudentScreen> createState() => _CurrentStudentScreenState();
}

class _CurrentStudentScreenState extends State<CurrentStudentScreen> {
  // 🔹 Current Student Data (can come from API later)
  Map<String, dynamic> currentStudent = {
    "token": 12,
    "name": "Sakshi Patil",
    "purpose": "Document Verification",
    "status": "In Progress",
  };

  // 🔹 Mark Student as Completed
  void completeStudent() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete Student"),
        content: const Text("Are you sure you want to complete this student?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentStudent["status"] = "Done";
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Student marked as completed")),
              );
            },
            child: const Text("Complete"),
          ),
        ],
      ),
    );
  }

  // 🔹 Skip Student
  void skipStudent() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Skip Student"),
        content: const Text("Do you want to skip this student?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentStudent["status"] = "Waiting";
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Student skipped")));
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Current Student"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStudent["status"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Token Number
                Text(
                  "TOKEN ${currentStudent["token"]}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Student Name
                Text(
                  currentStudent["name"],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                // 🔹 Purpose
                Text(
                  currentStudent["purpose"],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // 🔹 Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ⏭ Skip
                    ElevatedButton.icon(
                      onPressed: skipStudent,
                      icon: const Icon(Icons.skip_next),
                      label: const Text("Skip"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // ✅ Complete
                    ElevatedButton.icon(
                      onPressed: completeStudent,
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Complete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
