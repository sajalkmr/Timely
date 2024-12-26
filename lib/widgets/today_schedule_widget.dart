import 'package:flutter/material.dart';
import '../models/timetable_data.dart';

class TodayScheduleWidget extends StatelessWidget {
  const TodayScheduleWidget({
    super.key,
    required this.semester,
    required this.section,
  });

  final String semester;
  final String section;

  String _getDayName() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[now.weekday - 1];
  }

  List<TimeSlot> _getTodaySchedule() {
    final dayName = _getDayName();
    final schedule = timetableData[semester]?[section]?['timetable'] ?? [];
    final todaySchedule = schedule.firstWhere(
      (day) => day.day == dayName,
      orElse: () => DaySchedule(day: dayName, slots: []),
    );
    return todaySchedule.slots;
  }

  Color _getClassColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type.toLowerCase()) {
      case 'lab':
        return isDark ? Colors.blue.shade800 : Colors.blue.shade100;
      case 'lunch':
        return isDark ? Colors.orange.shade800 : Colors.orange.shade100;
      case 'break':
        return isDark ? Colors.grey.shade700 : Colors.grey.shade200;
      case 'project':
        return isDark ? Colors.green.shade800 : Colors.green.shade100;
      case 'activity':
        return isDark ? Colors.purple.shade800 : Colors.purple.shade100;
      case 'training':
        return isDark ? Colors.amber.shade800 : Colors.amber.shade100;
      default:
        return isDark ? const Color(0xFF303030) : Colors.white;
    }
  }

  String _getClassType(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('lab')) return 'lab';
    if (subjectLower.contains('lunch')) return 'lunch';
    if (subjectLower.contains('break')) return 'break';
    if (subjectLower.contains('project')) return 'project';
    if (subjectLower.contains('club') || subjectLower.contains('activity')) {
      return 'activity';
    }
    if (subjectLower.contains('tyl')) return 'training';
    return 'regular';
  }

  @override
  Widget build(BuildContext context) {
    final todaySchedule = _getTodaySchedule();
    final now = DateTime.now();
    final currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getDayName(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todaySchedule.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No classes today'),
                ),
              )
            else
              ...todaySchedule.map((slot) {
                final isCurrentClass = currentTimeStr.compareTo(slot.time.split('-')[0]) >= 0 &&
                    currentTimeStr.compareTo(slot.time.split('-')[1]) <= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _getClassColor(_getClassType(slot.subject), context),
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrentClass
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: ListTile(
                    title: Text(
                      slot.subject,
                      style: TextStyle(
                        fontWeight: isCurrentClass ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Text(
                      slot.time,
                      style: TextStyle(
                        fontWeight: isCurrentClass ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
