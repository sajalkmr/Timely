class TimeSlot {
  final String time;
  final String subject;
  String? note;  
  final DateTime? reminderTime;  

  TimeSlot({
    required this.time, 
    required this.subject, 
    this.note,
    this.reminderTime,
  });

  void addNote(String newNote) {
    note = newNote;
  }

  TimeSlot copyWithReminder(DateTime reminder) {
    return TimeSlot(
      time: time,
      subject: subject,
      note: note,
      reminderTime: reminder,
    );
  }
}

class DaySchedule {
  final String day;
  final List<TimeSlot> slots;

  DaySchedule({required this.day, required this.slots});
}

final Map<String, Map<String, Map<String, List<DaySchedule>>>> timetableData = {
  "5": {
    "C": {
      "timetable": [
        DaySchedule(
          day: "Mon",
          slots: [
            TimeSlot(time: "8:00-9:00", subject: "Python Lab"),
            TimeSlot(time: "9:00-10:00", subject: "Python Lab"),
            TimeSlot(time: "10:00-10:20", subject: "Break"),
            TimeSlot(time: "10:20-11:20", subject: "AI"),
            TimeSlot(time: "11:20-12:20", subject: "SE"),
            TimeSlot(time: "12:20-1:00", subject: "Lunch Break"),
            TimeSlot(time: "1:00-2:00", subject: "SE"),
            TimeSlot(time: "2:00-3:00", subject: "TOC"),
            TimeSlot(time: "3:00-4:00", subject: "TYL SS"),
          ],
        ),
        DaySchedule(
          day: "Tue",
          slots: [
            TimeSlot(time: "8:00-9:00", subject: "SE"),
            TimeSlot(time: "9:00-10:00", subject: "AI"),
            TimeSlot(time: "10:00-10:20", subject: "Break"),
            TimeSlot(time: "10:20-11:20", subject: "CN Lab"),
            TimeSlot(time: "11:20-12:20", subject: "CN Lab"),
            TimeSlot(time: "12:20-1:00", subject: "Lunch Break"),
            TimeSlot(time: "1:00-2:00", subject: "CN"),
            TimeSlot(time: "2:00-3:00", subject: "TYL SS"),
            TimeSlot(time: "3:00-4:00", subject: "MAD"),
          ],
        ),
        DaySchedule(
          day: "Wed",
          slots: [
            TimeSlot(time: "8:00-9:00", subject: "TYL APTI"),
            TimeSlot(time: "9:00-10:00", subject: "MAD Lab"),
            TimeSlot(time: "10:00-10:20", subject: "Break"),
            TimeSlot(time: "10:20-11:20", subject: "MAD Lab"),
            TimeSlot(time: "11:20-12:20", subject: "MAD Lab"),
            TimeSlot(time: "12:20-1:00", subject: "Lunch Break"),
            TimeSlot(time: "1:00-2:00", subject: "SE"),
            TimeSlot(time: "2:00-3:00", subject: "Club Activity"),
            TimeSlot(time: "3:00-4:00", subject: "Mini Projects"),
          ],
        ),
        DaySchedule(
          day: "Thu",
          slots: [
            TimeSlot(time: "8:00-9:00", subject: "CN"),
            TimeSlot(time: "9:00-10:00", subject: "AI Lab"),
            TimeSlot(time: "10:00-10:20", subject: "Break"),
            TimeSlot(time: "10:20-11:20", subject: "AI Lab"),
            TimeSlot(time: "11:20-12:20", subject: "AI Lab"),
            TimeSlot(time: "12:20-1:00", subject: "Lunch Break"),
            TimeSlot(time: "1:00-2:00", subject: "SE"),
            TimeSlot(time: "2:00-3:00", subject: "TOC"),
            TimeSlot(time: "3:00-4:00", subject: "DV Lab"),
          ],
        ),
        DaySchedule(
          day: "Fri",
          slots: [
            TimeSlot(time: "8:00-9:00", subject: "TOC Lab"),
            TimeSlot(time: "9:00-10:00", subject: "TOC Lab"),
            TimeSlot(time: "10:00-10:20", subject: "Break"),
            TimeSlot(time: "10:20-11:20", subject: "TYL APTI"),
            TimeSlot(time: "11:20-12:20", subject: "RM"),
            TimeSlot(time: "12:20-1:00", subject: "Lunch Break"),
            TimeSlot(time: "1:00-2:00", subject: "SE Lab"),
            TimeSlot(time: "2:00-3:00", subject: "SE Lab"),
            TimeSlot(time: "3:00-4:00", subject: "SE Lab"),
          ],
        ),
        DaySchedule(
          day: "Sat",
          slots: [
            TimeSlot(time: "8:00-9:00", subject: "RM"),
            TimeSlot(time: "9:00-10:00", subject: "AI"),
            TimeSlot(time: "10:00-10:20", subject: "Break"),
            TimeSlot(time: "10:20-11:20", subject: "SE"),
            TimeSlot(time: "11:20-12:20", subject: "TOC"),
            TimeSlot(time: "12:20-1:00", subject: "Lunch Break"),
            TimeSlot(time: "1:00-2:00", subject: "Mini Projects"),
            TimeSlot(time: "2:00-3:00", subject: "DV Lab"),
            TimeSlot(time: "3:00-4:00", subject: "DV Lab"),
          ],
        ),
      ],
    },
  },
};
