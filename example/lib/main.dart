import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:notification_listener_service_fixed/notification_event.dart';
import 'package:notification_listener_service_fixed/notification_listener_service.dart';

import 'AnsiLogViewer.dart';
import 'LogUtil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化日志工具
  await LogUtil.init(
    enableLog: true, // 生产环境自动关闭
    logDirName: "my_app_logs", // 自定义目录名
  );
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  List<ServiceNotificationEvent> events = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showLogFile(BuildContext context) async {
    final String? logDirPath = await LogUtil.logDirPath;
    if (logDirPath == null) {
      log("Log directory path is null.");
      return;
    }

    final File logFile = File(logDirPath);
    if (!logFile.existsSync()) {
      log("Log file does not exist. $logFile");
      return;
    }

    try {
      final String logContent = await logFile.readAsString(
        encoding: const Utf8Codec(allowMalformed: true),
      );


      final mediaQuery = MediaQuery.of(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("View Log File"),
          content: SizedBox(
            width: mediaQuery.size.width ,
            height: mediaQuery.size.height ,
            child: AnsiLogViewer(logContent),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text("Close"),
            )
          ],
        ),
      );
    } catch (e) {
      log("Failed to read log file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final res = await NotificationListenerService
                            .requestPermission();
                        log("Is enabled: $res");
                      },
                      child: const Text("Request Permission"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () async {
                        final bool res = await NotificationListenerService
                            .isPermissionGranted();
                        log("Is enabled: $res");
                      },
                      child: const Text("Check Permission"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () async {
                        var activeNotifications = await NotificationListenerService.getActiveNotifications();

                        for (var notification in activeNotifications) {
                          log("Notification: $notification");
                        }
                        setState(() {
                          events.addAll( activeNotifications);
                        });
                      },
                      child: const Text("active notifications"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        _subscription = NotificationListenerService
                            .notificationsStream
                            .listen((event) {
                          log("$event");
                          setState(() {
                            events.add(event);
                          });
                        });
                      },
                      child: const Text("Start Stream"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        _subscription?.cancel();
                      },
                      child: const Text("Stop Stream"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: ()=> _showLogFile(context),
                      child: const Text("Show log"),
                    ),
                    const SizedBox(height: 20.0),
                    TextButton(
                      onPressed: ()=> LogUtil().delLog(),
                      child: const Text("Delete log"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      onTap: () async {
                        try {
                          await events[index]
                              .sendReply("This is an auto response");
                        } catch (e) {
                          log(e.toString());
                        }
                      },
                      trailing: events[index].hasRemoved!
                          ? const Text(
                              "Removed",
                              style: TextStyle(color: Colors.red),
                            )
                          : const SizedBox.shrink(),
                      leading: events[index].appIcon == null
                          ? const SizedBox.shrink()
                          : Image.memory(
                              events[index].appIcon!,
                              width: 35.0,
                              height: 35.0,
                            ),
                      title: Text(events[index].title ?? "No title"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            events[index].content ?? "no content",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          events[index].canReply!
                              ? const Text(
                                  "Replied with: This is an auto reply",
                                  style: TextStyle(color: Colors.purple),
                                )
                              : const SizedBox.shrink(),
                          events[index].largeIcon != null
                              ? Image.memory(
                                  events[index].largeIcon!,
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
