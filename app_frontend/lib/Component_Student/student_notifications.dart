// ignore_for_file: use_build_context_synchronously

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
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  bool isLoading = true;
  bool isDeleting = false;
  List<dynamic> notifications = [];
  String errorMsg = "";
  String currentLanguage = 'english';

  // Multi-select state
  bool isSelectionMode = false;
  final Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    fetchNotifications();
  }

  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage(widget.studentId);
    if (mounted) {
      setState(() {
        currentLanguage = lang;
      });
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/notifications/${widget.studentId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          if (mounted) {
            setState(() {
              notifications = data["data"] ?? [];
              isLoading = false;
              // Clean up selectedIds that no longer exist
              final validIds = notifications.map((n) => n['_id'].toString()).toSet();
              selectedIds.removeWhere((id) => !validIds.contains(id));
              if (selectedIds.isEmpty && isSelectionMode) {
                isSelectionMode = false;
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMsg = "Failed to load notifications.";
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMsg = "Error: ${response.statusCode}";
            isLoading = false;
          });
        }
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
      if (response.statusCode == 200 && mounted) {
        setState(() {
          notifications[index]['isRead'] = true;
        });
      }
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
        if (selectedIds.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (selectedIds.length == notifications.length) {
        selectedIds.clear();
        isSelectionMode = false;
      } else {
        for (var n in notifications) {
          if (n['_id'] != null) {
            selectedIds.add(n['_id'].toString());
          }
        }
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedIds.clear();
    });
  }

  // Permanently delete a single notification
  Future<void> _deleteSingleNotification(String notificationId) async {
    setState(() => isDeleting = true);
    try {
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/notifications/$notificationId"),
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.removeWhere((n) => n['_id'] == notificationId);
          selectedIds.remove(notificationId);
          if (selectedIds.isEmpty) {
            isSelectionMode = false;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Translations.translate('notifications_deleted', currentLanguage),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete notification"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }

  // Permanently delete selected notifications
  Future<void> _deleteSelectedNotifications() async {
    if (selectedIds.isEmpty) return;

    setState(() => isDeleting = true);
    try {
      final idsList = selectedIds.toList();
      http.Response response;

      // If all are selected, use the clean all endpoint or bulk endpoint
      if (selectedIds.length == notifications.length) {
        response = await http.delete(
          Uri.parse("${ApiConfig.baseUrl}/notifications/all/${widget.studentId}"),
        );
      } else {
        response = await http.post(
          Uri.parse("${ApiConfig.baseUrl}/notifications/delete-multiple"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"ids": idsList}),
        );
      }

      if (response.statusCode == 200) {
        setState(() {
          notifications.removeWhere((n) => selectedIds.contains(n['_id'].toString()));
          selectedIds.clear();
          isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Translations.translate('notifications_deleted', currentLanguage),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete selected notifications"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }

  // Confirmation dialog for single delete
  void _confirmDeleteSingle(String notificationId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Translations.translate('delete_notification', currentLanguage),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.translate('delete_confirm_single', currentLanguage),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.translate('action_cannot_be_undone', currentLanguage),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              Translations.translate('cancel', currentLanguage),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSingleNotification(notificationId);
            },
            child: Text(
              Translations.translate('permanent_delete', currentLanguage),
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation dialog for selected delete
  void _confirmDeleteSelected() {
    if (selectedIds.isEmpty) return;

    final count = selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${Translations.translate('delete_notifications', currentLanguage)} ($count)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.translate('delete_confirm_multiple', currentLanguage),
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.translate('action_cannot_be_undone', currentLanguage),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              Translations.translate('cancel', currentLanguage),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSelectedNotifications();
            },
            child: Text(
              Translations.translate('permanent_delete', currentLanguage),
            ),
          ),
        ],
      ),
    );
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
    final allSelected = notifications.isNotEmpty &&
        selectedIds.length == notifications.length;

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: Translations.translate('cancel', currentLanguage),
                  onPressed: _exitSelectionMode,
                )
              : null,
          title: Text(
            isSelectionMode
                ? "${selectedIds.length} ${Translations.translate('selected', currentLanguage)}"
                : Translations.translate('Notifications', currentLanguage),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            if (isSelectionMode) ...[
              IconButton(
                icon: Icon(
                  allSelected ? Icons.check_box : Icons.select_all,
                  color: Colors.white,
                ),
                tooltip: allSelected
                    ? Translations.translate('deselect_all', currentLanguage)
                    : Translations.translate('select_all', currentLanguage),
                onPressed: _selectAll,
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                tooltip: Translations.translate('delete', currentLanguage),
                onPressed: selectedIds.isNotEmpty ? _confirmDeleteSelected : null,
              ),
            ] else if (notifications.isNotEmpty) ...[
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (val) {
                  if (val == 'select') {
                    setState(() {
                      isSelectionMode = true;
                    });
                  } else if (val == 'select_all') {
                    setState(() {
                      isSelectionMode = true;
                      for (var n in notifications) {
                        if (n['_id'] != null) {
                          selectedIds.add(n['_id'].toString());
                        }
                      }
                    });
                  } else if (val == 'clear_all') {
                    setState(() {
                      for (var n in notifications) {
                        if (n['_id'] != null) {
                          selectedIds.add(n['_id'].toString());
                        }
                      }
                    });
                    _confirmDeleteSelected();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'select',
                    child: Row(
                      children: [
                        const Icon(Icons.checklist, color: Colors.deepPurple, size: 20),
                        const SizedBox(width: 10),
                        Text(Translations.translate('select_all', currentLanguage)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          Translations.translate('delete_notifications', currentLanguage),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: isDeleting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.deepPurple),
                    SizedBox(height: 16),
                    Text(
                      "Deleting...",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : errorMsg.isNotEmpty
                    ? Center(child: Text(errorMsg))
                    : notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  Translations.translate(
                                      'no_new_notifications', currentLanguage),
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.deepPurple,
                            onRefresh: fetchNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                final String notificationId =
                                    notification['_id']?.toString() ?? "";
                                final isRead = notification['isRead'] ?? false;
                                final isSelected =
                                    selectedIds.contains(notificationId);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  elevation: isSelected ? 4 : (isRead ? 1 : 2.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: isSelected
                                        ? const BorderSide(
                                            color: Colors.deepPurple,
                                            width: 1.8,
                                          )
                                        : BorderSide.none,
                                  ),
                                  color: isSelected
                                      ? Colors.deepPurple.shade50
                                      : isRead
                                          ? Theme.of(context).cardColor
                                          : Colors.deepPurple.shade50.withValues(alpha: 0.4),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      if (isSelectionMode) {
                                        _toggleSelection(notificationId);
                                      } else {
                                        if (!isRead) {
                                          markAsRead(notificationId, index);
                                        }
                                      }
                                    },
                                    onLongPress: () {
                                      if (!isSelectionMode) {
                                        setState(() {
                                          isSelectionMode = true;
                                          selectedIds.add(notificationId);
                                        });
                                      } else {
                                        _toggleSelection(notificationId);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Selection checkbox or notification icon
                                          if (isSelectionMode)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8, top: 2),
                                              child: Checkbox(
                                                value: isSelected,
                                                activeColor: Colors.deepPurple,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                onChanged: (_) {
                                                  _toggleSelection(
                                                      notificationId);
                                                },
                                              ),
                                            )
                                          else
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 12, top: 2),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isRead
                                                      ? Colors.grey.shade200
                                                      : Colors.deepPurple.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.notifications_active,
                                                  size: 22,
                                                  color: isRead
                                                      ? Colors.grey.shade600
                                                      : Colors.deepPurple,
                                                ),
                                              ),
                                            ),

                                          // Notification Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notification['title'] ??
                                                      "Notification",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: isRead
                                                        ? FontWeight.w500
                                                        : FontWeight.bold,
                                                    color: isRead
                                                        ? Colors.black87
                                                        : Colors.deepPurple.shade900,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  notification['body'] ?? "",
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    color: Colors.grey.shade800,
                                                    height: 1.25,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 13,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formatTimestamp(
                                                          notification[
                                                              'createdAt']),
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        color:
                                                            Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Single delete action button (when not in multi-selection mode)
                                          if (!isSelectionMode)
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                size: 22,
                                                color: Colors.grey.shade500,
                                              ),
                                              tooltip: Translations.translate(
                                                  'delete_notification',
                                                  currentLanguage),
                                              onPressed: () =>
                                                  _confirmDeleteSingle(
                                                      notificationId),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
      ),
    );
  }
}
