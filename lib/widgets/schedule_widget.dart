import 'package:flutter/material.dart';
import 'today_schedule_widget.dart';

class ScheduleWidget extends StatelessWidget {
  const ScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodayScheduleWidget(
      semester: '5',
      section: 'C',
    );
  }
}
