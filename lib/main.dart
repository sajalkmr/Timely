import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';  
import 'models/timetable_data.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'updateScheduleWidget':
        try {
          final prefs = await SharedPreferences.getInstance();
          
          // Convert timetable data to JSON
          final schedule = timetableData['5']?['C']?['timetable'] ?? [];
          final scheduleJson = jsonEncode({
            'Mon': schedule[0].slots.map((s) => {'time': s.time, 'subject': s.subject}).toList(),
            'Tue': schedule[1].slots.map((s) => {'time': s.time, 'subject': s.subject}).toList(),
            'Wed': schedule[2].slots.map((s) => {'time': s.time, 'subject': s.subject}).toList(),
            'Thu': schedule[3].slots.map((s) => {'time': s.time, 'subject': s.subject}).toList(),
            'Fri': schedule[4].slots.map((s) => {'time': s.time, 'subject': s.subject}).toList(),
          });
          
          await prefs.setString('schedule_data', scheduleJson);
        } catch (e) {
          print('Error updating widget: $e');
        }
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  
  // Schedule periodic widget updates
  await Workmanager().registerPeriodicTask(
    'updateScheduleWidget',
    'updateScheduleWidget',
    frequency: const Duration(minutes: 15),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'College Timetable',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: Color(0xFF1E1E1E),    // Lighter dark surface
          background: Color(0xFF1E1E1E),  // Lighter dark background
        ),
        scaffoldBackgroundColor: Color(0xFF1E1E1E),  // Lighter dark scaffold
      ),
      themeMode: themeProvider.themeMode,
      home: TimeTableViewer(),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class TimeTableViewer extends StatefulWidget {
  const TimeTableViewer({super.key});

  @override
  State<TimeTableViewer> createState() => _TimeTableViewerState();
}

class _TimeTableViewerState extends State<TimeTableViewer> {
  Timer? _timer;
  String selectedSemester = '5';
  String selectedSection = 'C';
  DateTime currentTime = DateTime.now();

  Color getSubjectColor(String subject, String type) {
    if (type == 'break' || type == 'lunch') {
      return Colors.grey.shade200;
    }
    
    // Generate consistent colors based on subject name
    final hash = subject.hashCode;
    final hue = (hash % 360).abs();
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.3, 0.9).toColor();
  }

  @override
  void initState() {
    super.initState();
    // Start timer to update current class
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {});  // Trigger rebuild to update current class
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  TimeSlot? getCurrentClass() {
    final now = DateTime.now();
    final currentDay = now.weekday;
    
    if (currentDay > 5) return null;
    
    final schedule = timetableData[selectedSemester]?[selectedSection]?['timetable']?[currentDay - 1];
    if (schedule == null) return null;

    for (var slot in schedule.slots) {
      final times = slot.time.split('-');
      if (times.length != 2) continue;

      // Parse start and end times
      final startParts = times[0].trim().split(':');
      final endParts = times[1].trim().split(':');
      
      if (startParts.length != 2 || endParts.length != 2) continue;

      final startTime = TimeOfDay(
        hour: int.parse(startParts[0]), 
        minute: int.parse(startParts[1])
      );
      final endTime = TimeOfDay(
        hour: int.parse(endParts[0]), 
        minute: int.parse(endParts[1])
      );
      
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
      
      // Compare minutes since midnight
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      if (currentMinutes >= startMinutes && 
          currentMinutes <= endMinutes &&
          !slot.subject.toLowerCase().contains('break') &&
          !slot.subject.toLowerCase().contains('lunch')) {
        return slot;
      }
    }
    return null;
}

TimeSlot? getNextClass() {
    final now = DateTime.now();
    final currentDay = now.weekday;
    
    if (currentDay > 5) return null;
    
    final schedule = timetableData[selectedSemester]?[selectedSection]?['timetable']?[currentDay - 1];
    if (schedule == null) return null;

    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;

    // Find next class today
    TimeSlot? nextSlot;
    int? earliestNextStart;

    for (var slot in schedule.slots) {
      if (slot.subject.toLowerCase().contains('break') ||
          slot.subject.toLowerCase().contains('lunch')) {
        continue;
      }

      final times = slot.time.split('-');
      if (times.length != 2) continue;

      final startParts = times[0].trim().split(':');
      if (startParts.length != 2) continue;

      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

      if (startMinutes > currentMinutes) {
        if (earliestNextStart == null || startMinutes < earliestNextStart) {
          earliestNextStart = startMinutes;
          nextSlot = slot;
        }
      }
    }

    if (nextSlot != null) return nextSlot;

    // If no next class today and not Friday, get first class of next day
    if (currentDay < 5) {
      final nextDaySchedule = timetableData[selectedSemester]?[selectedSection]?['timetable']?[currentDay];
      if (nextDaySchedule != null) {
        for (var slot in nextDaySchedule.slots) {
          if (!slot.subject.toLowerCase().contains('break') &&
              !slot.subject.toLowerCase().contains('lunch')) {
            return slot;
          }
        }
      }
    }
    return null;
}

  String getClassType(String subject) {
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

  Color getClassColor(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case 'lab':
        return isDark ? Colors.blue.shade700 : Colors.blue.shade100;
      case 'lunch':
        return isDark ? Colors.orange.shade700 : Colors.orange.shade100;
      case 'break':
        return isDark ? Colors.grey.shade600 : Colors.grey.shade200;
      case 'project':
        return isDark ? Colors.green.shade700 : Colors.green.shade100;
      case 'activity':
        return isDark ? Colors.purple.shade700 : Colors.purple.shade100;
      case 'training':
        return isDark ? Colors.amber.shade700 : Colors.amber.shade100;
      default:
        return isDark ? Color(0xFF2D2D2D) : Colors.white;  // Lighter dark default
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentClass = getCurrentClass();
    final nextClass = getNextClass();
    final schedule = timetableData[selectedSemester]?[selectedSection]?['timetable'];
    
    // Safely check if schedule exists and has data
    if (schedule == null || (schedule as List).isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No schedule data available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('College Timetable'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Current and Next class cards
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Class Card
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (currentClass != null) ...[
                              SizedBox(height: 12),
                              Text(
                                currentClass.subject,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  currentClass.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ] else
                              Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'No class right now',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Next Class Card
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.next_plan,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'NEXT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (nextClass != null) ...[
                              SizedBox(height: 12),
                              Text(
                                nextClass.subject,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  nextClass.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ] else
                              Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'No more classes today',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Timetable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Table(
                    border: TableBorder.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: {
                      0: FixedColumnWidth(50), // Day column width
                      for (var i = 1; i <= (schedule[0].slots as List).length; i++)
                        i: FlexColumnWidth(),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        children: [
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Day',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          ...schedule[0].slots.map((slot) => TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                slot.time,
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                        ],
                      ),
                      // Data rows
                      ...schedule.map((day) => TableRow(
                        children: [
                          TableCell(
                            child: Container(
                              padding: EdgeInsets.all(8.0),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Text(
                                day.day,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          ...day.slots.map((slot) {
                            final type = getClassType(slot.subject);
                            return TableCell(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: getClassColor(type),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                    width: 0.5,
                                  ),
                                ),
                                height: 35,
                                alignment: Alignment.center,
                                child: Text(
                                  slot.subject,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: type == 'break' || type == 'lunch'
                                        ? Theme.of(context).colorScheme.onSurfaceVariant
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: type == 'break' || type == 'lunch'
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildLegendItem('Regular', getClassColor('regular')),
                  _buildLegendItem('Lab', getClassColor('lab')),
                  _buildLegendItem('Break', getClassColor('break')),
                  _buildLegendItem('Lunch', getClassColor('lunch')),
                  _buildLegendItem('Project', getClassColor('project')),
                  _buildLegendItem('Activity', getClassColor('activity')),
                  _buildLegendItem('Training', getClassColor('training')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
