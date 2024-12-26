import 'package:flutter/material.dart';
import '../models/timetable_data.dart';
import '../widgets/weekly_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<DaySchedule> filteredSchedule = [];
  TimeSlot? selectedSlot;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    filteredSchedule = timetableData["5"]?["C"]?["timetable"] ?? [];
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _showAddNoteDialog(TimeSlot slot) {
    _noteController.text = slot.note ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Enter your note',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      slot.addNote(_noteController.text);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Note added for ${slot.subject}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Save Note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _filterSchedule(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSchedule = timetableData["5"]?["C"]?["timetable"] ?? [];
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      filteredSchedule = (timetableData["5"]?["C"]?["timetable"] ?? [])
          .map((day) {
            final filteredSlots = day.slots.where((slot) =>
                slot.subject.toLowerCase().contains(lowercaseQuery) ||
                (slot.note?.toLowerCase().contains(lowercaseQuery) ?? false));
            return DaySchedule(
              day: day.day,
              slots: filteredSlots.toList(),
            );
          })
          .where((day) => day.slots.isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Schedule'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search subjects or notes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterSchedule,
            ),
          ),
          Expanded(
            child: WeeklyView(
              weekSchedule: filteredSchedule,
              onSlotTap: _showAddNoteDialog,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
