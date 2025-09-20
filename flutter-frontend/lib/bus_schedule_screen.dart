// bus_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'theme_notifier.dart';

class BusScheduleScreen extends StatefulWidget {
  const BusScheduleScreen({super.key});

  @override
  State<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen>
    with SingleTickerProviderStateMixin {
  int _selectedView = 0; // 0: Day, 1: Week, 2: Month
  int _selectedRouteType = 0; // 0: City to City, 1: City to Village, 2: Intercity
  bool _isLoading = true;
  final String _errorMessage = '';

  // Calendar/Date variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  // Animation
  late AnimationController _animationController;

  // Sample data
  List<Map<String, dynamic>> _cityToCityRoutes = [];
  final List<Map<String, dynamic>> _cityToVillageRoutes = [];
  final List<Map<String, dynamic>> _intercityRoutes = [];

  // Week view data structure
  final Map<DateTime, List<Map<String, dynamic>>> _weeklySchedules = {};
  
  // Month view data structure
  final Map<DateTime, List<Map<String, dynamic>>> _monthlySchedules = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _fetchScheduleData();
    _generateSampleWeekData();
    _generateSampleMonthData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchScheduleData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _cityToCityRoutes = [
        {
          'time': '05:00', 
          'name': 'Downtown Express', 
          'destination': 'Business District', 
          'status': 'Active',
          'startPoint': 'City Center',
          'startLat': 40.7128,
          'startLng': -74.0060,
          'endLat': 40.7589,
          'endLng': -73.9851,
        },
        {
          'time': '05:30', 
          'name': 'Metro Line 1', 
          'destination': 'Shopping Mall', 
          'status': 'Active',
          'startPoint': 'Central Station',
          'startLat': 40.7536,
          'startLng': -73.9772,
          'endLat': 40.7505,
          'endLng': -73.9934,
        },
      ];
      _isLoading = false;
    });
  }

  void _generateSampleWeekData() {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      _weeklySchedules[date] = List.from(_cityToCityRoutes);
    }
  }

  void _generateSampleMonthData() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    
    for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      final date = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
      if (i % 3 == 0) { 
        _monthlySchedules[date] = List.from(_cityToCityRoutes);
      }
    }
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
    });
    _fetchScheduleData();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _monthlySchedules[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _showRouteOnMap(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Route: ${route['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("From: ${route['startPoint']}"),
              Text("To: ${route['destination']}"),
              const SizedBox(height: 16),
              const Text("This would open a map showing the route from start to end."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Show Add Schedule Dialog
  void _showAddScheduleDialog() {
    final timeController = TextEditingController();
    final nameController = TextEditingController();
    final destinationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add New Schedule"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: "Time (e.g. 08:00)"),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Route Name"),
              ),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: "Destination"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (timeController.text.isNotEmpty &&
                    nameController.text.isNotEmpty &&
                    destinationController.text.isNotEmpty) {
                  _addSchedule(
                    timeController.text,
                    nameController.text,
                    destinationController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Add new schedule to the current route type
  void _addSchedule(String time, String name, String destination) {
    final newSchedule = {
      'time': time,
      'name': name,
      'destination': destination,
      'status': 'Scheduled',
      'startPoint': 'Custom Point',
      'startLat': 0.0,
      'startLng': 0.0,
      'endLat': 0.0,
      'endLng': 0.0,
    };

    setState(() {
      if (_selectedRouteType == 0) {
        _cityToCityRoutes.add(newSchedule);
      } else if (_selectedRouteType == 1) {
        _cityToVillageRoutes.add(newSchedule);
      } else {
        _intercityRoutes.add(newSchedule);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Schedule"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View Selection with Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildViewOption(Icons.calendar_today, "Day View", 0),
                      _buildViewOption(Icons.view_week, "Week View", 1),
                      _buildViewOption(Icons.calendar_month, "Month View", 2),
                    ],
                  ),

                  const Divider(height: 32),

                  // Route Type with Icons
                  Text("Route Type", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRouteTypeOption(Icons.location_city, "City to City", 0),
                      _buildRouteTypeOption(Icons.park, "City to Village", 1),
                      _buildRouteTypeOption(Icons.directions_bus, "Intercity", 2),
                    ],
                  ),

                  const Divider(height: 32),

                  // Show appropriate view based on selection
                  if (_selectedView == 0) _buildDayView(),
                  if (_selectedView == 1) _buildWeekView(),
                  if (_selectedView == 2) _buildMonthView(),
                ],
              ),
            ),

      // 🔹 Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Schedule for ${_formatDate(_focusedDay)}", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildScheduleList(_cityToCityRoutes),
      ],
    );
  }

  Widget _buildWeekView() {
    final weekDays = _getWeekDays(_focusedDay);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Week of ${_formatDate(weekDays.first)} - ${_formatDate(weekDays.last)}", 
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...weekDays.map((day) {
          final events = _weeklySchedules[DateTime(day.year, day.month, day.day)] ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDate(day), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              events.isNotEmpty 
                ? _buildScheduleList(events)
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text("No schedules for this day"),
                  ),
              const Divider(),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMonthView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Schedule for ${_formatMonth(_focusedDay)}", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_selectedDay != null) ...[
          Text("Schedules for ${_formatDate(_selectedDay!)}", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildScheduleList(_getEventsForDay(_selectedDay!)),
        ],
      ],
    );
  }

  Widget _buildViewOption(IconData icon, String title, int index) {
    final isSelected = _selectedView == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedView = index);
        _refreshData();
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRouteTypeOption(IconData icon, String title, int index) {
    final isSelected = _selectedRouteType == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRouteType = index);
        _refreshData();
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<Map<String, dynamic>> routes) {
    return Column(
      children: routes.map((route) {
        return Card(
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(route['time'], style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            title: Text(route['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("To: ${route['destination']}"),
            trailing: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => _showRouteOnMap(route),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper methods
  List<DateTime> _getWeekDays(DateTime date) {
    final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => firstDayOfWeek.add(Duration(days: index)));
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatMonth(DateTime date) {
    return "${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }
}