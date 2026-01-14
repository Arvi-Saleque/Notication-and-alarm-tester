import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  Map<String, PermissionStatus> permissionStatuses = {};
  bool isLoading = true;

  final List<Map<String, dynamic>> requiredPermissions = [
    {
      'name': 'Notifications',
      'description': 'Required to show notifications',
      'permission': Permission.notification,
      'critical': true,
    },
    {
      'name': 'Schedule Exact Alarms',
      'description': 'Required to schedule alarms and notifications at exact times',
      'permission': Permission.scheduleExactAlarm,
      'critical': true,
    },
    {
      'name': 'Battery Optimization',
      'description': 'Disable battery optimization to ensure alarms work when app is closed',
      'permission': Permission.ignoreBatteryOptimizations,
      'critical': true,
    },
    {
      'name': 'Display Over Other Apps',
      'description': 'Required to show alarm screen over lockscreen and other apps',
      'permission': Permission.systemAlertWindow,
      'critical': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => isLoading = true);

    for (var permInfo in requiredPermissions) {
      final permission = permInfo['permission'] as Permission;
      final status = await permission.status;
      permissionStatuses[permInfo['name'] as String] = status;
    }

    setState(() => isLoading = false);
  }

  Future<void> _requestPermission(String name, Permission permission) async {
    PermissionStatus status;
    
    if (permission == Permission.scheduleExactAlarm) {
      // For exact alarms, we need to open settings directly
      await permission.request();
      status = await permission.status;
    } else if (permission == Permission.ignoreBatteryOptimizations) {
      // Battery optimization needs special handling
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'You will be taken to settings to disable battery optimization. '
            'Find this app in the list and select "Don\'t optimize" or "Unrestricted".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (result == true) {
        await permission.request();
        status = await permission.status;
      } else {
        return;
      }
    } else {
      status = await permission.request();
    }

    setState(() {
      permissionStatuses[name] = status;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isGranted
                ? '$name permission granted!'
                : '$name permission denied',
          ),
          backgroundColor: status.isGranted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      if (Platform.isAndroid) {
        // Open app details settings which shows all permissions
        await openAppSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.grey;
      case PermissionStatus.limited:
        return Colors.yellow;
      case PermissionStatus.provisional:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.denied:
        return Icons.warning;
      case PermissionStatus.permanentlyDenied:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  Future<void> _requestAllPermissions() async {
    for (var permInfo in requiredPermissions) {
      final name = permInfo['name'] as String;
      final permission = permInfo['permission'] as Permission;
      final status = permissionStatuses[name];

      if (status == null || !status.isGranted) {
        await _requestPermission(name, permission);
        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkPermissions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Card(
                    color: Colors.blue,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Permission Status',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Note: Some permissions may show as "Granted" but not actually work. '
                            'You MUST manually verify all permissions in Settings.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...requiredPermissions.map((permInfo) {
                    final name = permInfo['name'] as String;
                    final description = permInfo['description'] as String;
                    final permission = permInfo['permission'] as Permission;
                    final isCritical = permInfo['critical'] as bool;
                    final status = permissionStatuses[name];

                    if (status == null) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 32,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isCritical) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(description),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Status: ${_getStatusText(status)}',
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: status.isGranted
                            ? null
                            : ElevatedButton(
                                onPressed: () =>
                                    _requestPermission(name, permission),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Grant'),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.alarm, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'CRITICAL: Alarm Setup Required',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'For alarms to work when app is closed:\n\n'
                            '✓ Go to Settings → Apps → Notify Tester\n\n'
                            '1. Notifications → Enable "Alarms & reminders"\n'
                            '2. Battery → "Don\'t optimize" or "Unrestricted"\n'
                            '3. Battery → "Allow background activity"\n'
                            '4. Auto-launch → Enable (OnePlus/Oppo)\n'
                            '5. Display over other apps → Enable\n\n'
                            'OnePlus users: Disable "Deep Optimization" in Battery settings',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _openNotificationSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Open App Settings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _requestAllPermissions,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Request All Permissions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _checkPermissions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
