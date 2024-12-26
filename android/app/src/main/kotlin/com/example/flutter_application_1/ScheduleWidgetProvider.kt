package com.example.flutter_application_1

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import java.util.Calendar
import org.json.JSONObject
import org.json.JSONArray

class ScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update each widget
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun getDayOfWeek(): String {
        return when (Calendar.getInstance().get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> "Mon"
            Calendar.TUESDAY -> "Tue"
            Calendar.WEDNESDAY -> "Wed"
            Calendar.THURSDAY -> "Thu"
            Calendar.FRIDAY -> "Fri"
            else -> "Mon" // Default to Monday for weekends
        }
    }

    private fun getCurrentTime(): String {
        val calendar = Calendar.getInstance()
        val hour = calendar.get(Calendar.HOUR_OF_DAY).toString().padStart(2, '0')
        val minute = calendar.get(Calendar.MINUTE).toString().padStart(2, '0')
        return "$hour:$minute"
    }

    private fun isCurrentOrUpcoming(timeSlot: String): Boolean {
        val currentTime = getCurrentTime()
        val endTime = timeSlot.split("-")[1]
        return currentTime <= endTime
    }

    private fun isCurrentClass(timeSlot: String): Boolean {
        val currentTime = getCurrentTime()
        val times = timeSlot.split("-")
        return currentTime >= times[0] && currentTime <= times[1]
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Get the shared preferences
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val scheduleData = prefs.getString("flutter.schedule_data", null)
        
        // Create remote views
        val views = RemoteViews(context.packageName, R.layout.schedule_widget)
        
        // Update the title with current day
        val currentDay = getDayOfWeek()
        views.setTextViewText(R.id.widget_title, "Today's Schedule ($currentDay)")

        // Clear the schedule container
        views.removeAllViews(R.id.schedule_container)

        try {
            if (scheduleData != null) {
                val schedule = JSONObject(scheduleData)
                val daySchedule = schedule.getJSONArray(currentDay)
                var hasCurrentOrUpcoming = false
                var classCount = 0

                for (i in 0 until daySchedule.length()) {
                    val slot = daySchedule.getJSONObject(i)
                    val time = slot.getString("time")
                    val subject = slot.getString("subject")

                    // Only show current or upcoming classes
                    if (isCurrentOrUpcoming(time) && classCount < 4) {
                        hasCurrentOrUpcoming = true
                        classCount++

                        val itemView = RemoteViews(context.packageName, R.layout.schedule_item)
                        itemView.setTextViewText(R.id.time_text, time)
                        itemView.setTextViewText(R.id.subject_text, subject)

                        if (isCurrentClass(time)) {
                            itemView.setTextColor(R.id.time_text, Color.parseColor("#1976D2"))
                            itemView.setTextColor(R.id.subject_text, Color.parseColor("#1976D2"))
                            itemView.setTextViewText(R.id.subject_text, " $subject (Current)")
                        } else {
                            itemView.setTextViewText(R.id.subject_text, " $subject")
                        }

                        views.addView(R.id.schedule_container, itemView)
                    }
                }

                if (!hasCurrentOrUpcoming) {
                    val noClassView = RemoteViews(context.packageName, R.layout.schedule_item)
                    noClassView.setTextViewText(R.id.subject_text, "No more classes today")
                    views.addView(R.id.schedule_container, noClassView)
                }
            } else {
                val noDataView = RemoteViews(context.packageName, R.layout.schedule_item)
                noDataView.setTextViewText(R.id.subject_text, "No schedule data available")
                views.addView(R.id.schedule_container, noDataView)
            }
        } catch (e: Exception) {
            val errorView = RemoteViews(context.packageName, R.layout.schedule_item)
            errorView.setTextViewText(R.id.subject_text, "Error loading schedule")
            views.addView(R.id.schedule_container, errorView)
        }

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
