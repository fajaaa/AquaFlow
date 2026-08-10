import 'activity_log_item.dart';

class ActivityLogPage {
  const ActivityLogPage({required this.items, required this.totalCount});

  final List<ActivityLogItem> items;
  final int totalCount;
}
