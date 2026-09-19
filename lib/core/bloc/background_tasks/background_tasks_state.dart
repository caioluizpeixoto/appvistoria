import 'package:equatable/equatable.dart';

enum BackgroundTaskStatus { running, success, error }

class BackgroundTask extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final BackgroundTaskStatus status;
  final String? errorMessage;
  final dynamic resultData;
  final DateTime createdAt;
  final bool isRead;
  final String? redirectPath;
  final Map<String, dynamic>? redirectExtra;

  const BackgroundTask({
    required this.id,
    required this.title,
    required this.subtitle,
    this.status = BackgroundTaskStatus.running,
    this.errorMessage,
    this.resultData,
    required this.createdAt,
    this.isRead = false,
    this.redirectPath,
    this.redirectExtra,
  });

  BackgroundTask copyWith({
    String? id,
    String? title,
    String? subtitle,
    BackgroundTaskStatus? status,
    String? errorMessage,
    dynamic resultData,
    DateTime? createdAt,
    bool? isRead,
    String? redirectPath,
    Map<String, dynamic>? redirectExtra,
  }) {
    return BackgroundTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      resultData: resultData ?? this.resultData,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      redirectPath: redirectPath ?? this.redirectPath,
      redirectExtra: redirectExtra ?? this.redirectExtra,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        status,
        errorMessage,
        resultData,
        createdAt,
        isRead,
        redirectPath,
        redirectExtra,
      ];
}

class BackgroundTasksState extends Equatable {
  final List<BackgroundTask> tasks;

  const BackgroundTasksState({this.tasks = const []});

  BackgroundTasksState copyWith({
    List<BackgroundTask>? tasks,
  }) {
    return BackgroundTasksState(
      tasks: tasks ?? this.tasks,
    );
  }

  bool get hasRunningTasks =>
      tasks.any((task) => task.status == BackgroundTaskStatus.running);

  bool get hasUnreadCompletedTasks => tasks.any(
      (task) => task.status != BackgroundTaskStatus.running && !task.isRead);

  int get unreadCount => tasks
      .where((task) =>
          task.status != BackgroundTaskStatus.running && !task.isRead)
      .length;

  @override
  List<Object> get props => [tasks];
}
