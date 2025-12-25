import 'package:flutter/material.dart';

class ManageQueueScreen extends StatefulWidget {
  const ManageQueueScreen({super.key});

  @override
  State<ManageQueueScreen> createState() => _ManageQueueScreenState();
}

class _ManageQueueScreenState extends State<ManageQueueScreen> {
  // 🔹 Queue Data (Dummy Data)
  List<Map<String, dynamic>> queueList = [
    {"token": 1, "name": "Amit Sharma", "status": "Waiting"},
    {"token": 2, "name": "Priya Patil", "status": "Waiting"},
    {"token": 3, "name": "Rahul Verma", "status": "Waiting"},
  ];

  // 🔹 Start Next Student
  void startNext() {
    setState(() {
      for (var student in queueList) {
        if (student["status"] == "In Progress") {
          return; // already running
        }
      }
      for (var student in queueList) {
        if (student["status"] == "Waiting") {
          student["status"] = "In Progress";
          break;
        }
      }
    });
  }

  // 🔹 Pause Current Student
  void pauseCurrent(int index) {
    setState(() {
      if (queueList[index]["status"] == "In Progress") {
        queueList[index]["status"] = "Waiting";
      }
    });
  }

  // 🔹 Remove Student from Queue
  void removeStudent(int index) {
    setState(() {
      queueList.removeAt(index);
    });
  }

  // 🔹 Status Color
  Color getStatusColor(String status) {
    switch (status) {
      case "Waiting":
        return Colors.orange;
      case "In Progress":
        return Colors.blue;
      case "Done":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Queue"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: startNext,
            tooltip: "Start Next",
          ),
        ],
      ),

      body: queueList.isEmpty
          ? const Center(
              child: Text(
                "No students in queue",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: queueList.length,
              itemBuilder: (context, index) {
                final student = queueList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        student["token"].toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    title: Text(
                      student["name"],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      student["status"],
                      style: TextStyle(
                        color: getStatusColor(student["status"]),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ⏸ Pause Button
                        IconButton(
                          icon: const Icon(Icons.pause, color: Colors.orange),
                          onPressed: () => pauseCurrent(index),
                        ),

                        // ❌ Remove Button
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => removeStudent(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
