import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/api_config.dart';
import '../services/language_service.dart';
import '../services/translations.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final String studentId;

  const StudentNotificationsScreen({super.key, required this.studentId});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  bool isLoading = true;
  List<dynamic> notifications = [];
  String errorMsg = "";
  String currentLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    fetchNotifications();
  }

  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage(widget.studentId);
    setState(() {
      currentLanguage = lang;
    });
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/notifications/${widget.studentId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            notifications = data["data"] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMsg = "Failed to load notifications.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = "Error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMsg = "Unable to connect to server: $e";
          isLoading = false;
        });
      }
    }
  }

  Future<void> markAsRead(String notificationId, int index) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/notifications/$notificationId/read"),
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications[index]['isRead'] = true;
        });
      }
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.translate('Notifications', currentLanguage)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg))
              : notifications.isEmpty
                  ? Center(
                      child: Text(
                        Translations.translate('no_new_notifications', currentLanguage),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isRead = notification['isRead'] ?? false;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          elevation: isRead ? 1 : 3,
                          color: isRead ? Theme.of(context).cardColor : Colors.deepPurple.shade50,
                          child: ListTile(
                            leading: Icon(
                              Icons.notifications_active,
                              color: isRead ? Colors.grey : Colors.deepPurple,
                            ),
                            title: Text(
                              notification['title'] ?? "Notification",
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notification['body'] ?? ""),
                                const SizedBox(height: 8),
                                Text(
                                  formatTimestamp(notification['createdAt']),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!isRead) {
                                markAsRead(notification['_id'], index);
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
