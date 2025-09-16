import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const JourneyPlannerApp());
}

class JourneyPlannerApp extends StatelessWidget {
  const JourneyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journey Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const JourneyPlannerScreen(),
    );
  }
}

class JourneyPlannerScreen extends StatefulWidget {
  const JourneyPlannerScreen({super.key});

  @override
  State<JourneyPlannerScreen> createState() => _JourneyPlannerScreenState();
}

class _JourneyPlannerScreenState extends State<JourneyPlannerScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _tripButtonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  // Text editing controllers for search fields
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();
  final TextEditingController _switchingPointController =
      TextEditingController();

  // Focus nodes for search fields
  final FocusNode _startPointFocus = FocusNode();
  final FocusNode _endPointFocus = FocusNode();
  final FocusNode _switchingPointFocus = FocusNode();

  // Route type selection
  int _selectedRouteType =
      0; // 0: City to City, 1: City to Village, 2: Intercity

  // Mock data - would typically come from API calls
  final String routeName = "Route 15A - City Center";
  String currentLocation = "Central Mall Bus Stop";
  String destination = "Railway Station Terminal";
  String switchingPoint = "City Center Bus Terminal";

  final List<UpcomingStop> upcomingStops = [
    UpcomingStop(name: "Market Square", time: "2 min"),
    UpcomingStop(name: "City Hospital", time: "5 min"),
    UpcomingStop(name: "Railway Station", time: "12 min"),
  ];

  // Track if user has started a trip
  bool _tripStarted = false;
  bool _showSwitchingPoint = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _tripButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _tripButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start button pulsing animation
    _tripButtonAnimationController.repeat(reverse: true);

    // Auto-focus on the starting point field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_startPointFocus);
    });
  }

  @override
  void dispose() {
    _tripButtonAnimationController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    _switchingPointController.dispose();
    _startPointFocus.dispose();
    _endPointFocus.dispose();
    _switchingPointFocus.dispose();
    super.dispose();
  }

  // Function to handle start trip button tap
  void _handleStartTrip() {
    if (_startPointController.text.isEmpty ||
        _endPointController.text.isEmpty) {
      // Show error if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both starting point and destination"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Stop the pulsing animation
    _tripButtonAnimationController.stop();

    // Animate button press
    _tripButtonAnimationController.forward().then((_) {
      _tripButtonAnimationController.reverse();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Planning your route..."),
              ],
            ),
          );
        },
      );

      // Simulate API call delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Close loading dialog

        // Update with new route data (simulated)
        setState(() {
          currentLocation = _startPointController.text;
          destination = _endPointController.text;
          if (_showSwitchingPoint && _switchingPointController.text.isNotEmpty) {
            switchingPoint = _switchingPointController.text;
          }
          _tripStarted = true;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip started successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      });
    });
  }

  void _showSwitchingPointOnMap() {
    if (_switchingPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a switching point first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Switching Point Location"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _switchingPointController.text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        "Location of ${_switchingPointController.text}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route View"),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search fields (always shown at the top)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _startPointController,
                    focusNode: _startPointFocus,
                    style: const TextStyle(color: Colors.black), // ✅ added
                    decoration: InputDecoration(
                      labelText: 'Starting Point',
                      labelStyle:
                          const TextStyle(color: Colors.black), 
                      prefixIcon:
                          const Icon(Icons.my_location, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _endPointController,
                    focusNode: _endPointFocus,
                    style: const TextStyle(color: Colors.black), 
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      labelStyle:
                          const TextStyle(color: Colors.black), 
                      prefixIcon:
                          const Icon(Icons.location_on, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),

                  // Switching Point Section
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _showSwitchingPoint,
                        onChanged: (value) {
                          setState(() {
                            _showSwitchingPoint = value ?? false;
                          });
                        },
                      ),
                      const Text('Add Switching Point'),
                      const Spacer(),
                      if (_showSwitchingPoint)
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: _showSwitchingPointOnMap,
                        ),
                    ],
                  ),
                  if (_showSwitchingPoint) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _switchingPointController,
                      focusNode: _switchingPointFocus,
                      style: const TextStyle(color: Colors.black), 
                      decoration: InputDecoration(
                        labelText: 'Switching Point',
                        labelStyle:
                            const TextStyle(color: Colors.black), 
                        prefixIcon: const Icon(
                          Icons.transfer_within_a_station,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ],

                  // Route Type Selection
                  const SizedBox(height: 16),
                  const Text(
                    "Route Type",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRouteTypeOption(
                          Icons.location_city, "City to City", 0),
                      _buildRouteTypeOption(
                          Icons.park, "City to Village", 1),
                      _buildRouteTypeOption(
                          Icons.directions_bus, "Intercity", 2),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ScaleTransition(
                    scale: _buttonScaleAnimation,
                    child: ElevatedButton(
                      onPressed: _handleStartTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Trip',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Only show route details after trip has been started
            if (_tripStarted) ...[
              // Route information section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color.fromARGB(255, 25, 173, 210),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationRow(Icons.my_location, currentLocation),
                    const SizedBox(height: 8),
                    if (_showSwitchingPoint && switchingPoint.isNotEmpty) ...[
                      _buildLocationRow(
                          Icons.transfer_within_a_station, switchingPoint),
                      const SizedBox(height: 8),
                    ],
                    _buildLocationRow(Icons.location_on, destination),
                  ],
                ),
              ),

              // Map view section
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        "Map View",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Integration Required",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Upcoming stops section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upcoming Stops",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: upcomingStops.length,
                      itemBuilder: (context, index) {
                        return _buildStopItem(upcomingStops[index]);
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show prompt to start a trip
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Enter your starting point and destination to plan your journey",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTypeOption(IconData icon, String title, int index) {
    final isSelected = _selectedRouteType == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRouteType = index);
      },
      child: Column(
        children: [
          Icon(icon,
              color: isSelected ? Colors.blue : Colors.grey, size: 30),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopItem(UpcomingStop stop) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_pin,
                color: Color.fromARGB(255, 33, 201, 243), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stop.name,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Text(
            stop.time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
}

// Data model for upcoming stops
class UpcomingStop {
  final String name;
  final String time;

  UpcomingStop({required this.name, required this.time});
}