import 'package:flutter/material.dart';

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key});

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController queueName = TextEditingController();
  final TextEditingController maxStudents = TextEditingController();

  String department = "Admission";
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Create Queue"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Queue Name
                  TextFormField(
                    controller: queueName,
                    decoration: const InputDecoration(
                      labelText: "Queue Name",
                      prefixIcon: Icon(Icons.queue),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter queue name" : null,
                  ),
                  const SizedBox(height: 16),

                  // Department
                  DropdownButtonFormField(
                    // ignore: deprecated_member_use
                    value: department,
                    decoration: const InputDecoration(
                      labelText: "Department",
                      prefixIcon: Icon(Icons.apartment),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Admission",
                        child: Text("Admission"),
                      ),
                      DropdownMenuItem(value: "Exam", child: Text("Exam")),
                      DropdownMenuItem(value: "Fee", child: Text("Fee")),
                    ],
                    onChanged: (value) {
                      setState(() => department = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Max Students
                  TextFormField(
                    controller: maxStudents,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Max Students",
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter max students" : null,
                  ),
                  const SizedBox(height: 16),

                  // Start & End Time
                  Row(
                    children: [
                      Expanded(
                        child: _timePicker(
                          label: "Start Time",
                          time: startTime,
                          onTap: () async {
                            startTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timePicker(
                          label: "End Time",
                          time: endTime,
                          onTap: () async {
                            endTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Create Queue"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Queue Created Successfully"),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------- TIME PICKER UI --------
  Widget _timePicker({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(time == null ? "Select" : time.format(context)),
      ),
    );
  }
}
