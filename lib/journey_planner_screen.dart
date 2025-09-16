import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _selectedRouteType = 0;

  // Journey data
  String routeName = "Route 15A - City Center";
  String currentLocation = "Central Mall Bus Stop";
  String destination = "Railway Station Terminal";
  String switchingPoint = "City Center Bus Terminal";
  List<UpcomingStop> upcomingStops = [];

  // Track if user has started a trip
  bool _tripStarted = false;
  bool _showSwitchingPoint = false;
  bool _isLoading = false;

  // JWT Token
  String? _jwtToken;

  // API Base URL
  static const String baseUrl = "http://your-api-url:8080/api";

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initializeAnimations();
  }

  void _initializeApp() async {
    await _loadToken();
    _loadLocationSuggestions();
  }

  void _initializeAnimations() {
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

    _tripButtonAnimationController.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_startPointFocus);
    });
  }

  // JWT Token Management
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jwtToken = prefs.getString('jwt_token');
    });
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    setState(() {
      _jwtToken = token;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    setState(() {
      _jwtToken = null;
    });
  }

  // API Call: Get location suggestions
  Future<List<String>> _getLocationSuggestions(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes/suggestions?query=$query'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  // API Call: Plan journey
  Future<void> _planJourney() async {
    if (_startPointController.text.isEmpty || _endPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both starting point and destination"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> requestBody = {
        'startPoint': _startPointController.text,
        'endPoint': _endPointController.text,
        'switchingPoint': _showSwitchingPoint ? _switchingPointController.text : null,
        'routeType': _selectedRouteType,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/journey/plan'),
        headers: _getHeaders(),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        setState(() {
          routeName = data['routeName'];
          currentLocation = data['currentLocation'];
          destination = data['destination'];
          switchingPoint = data['switchingPoint'] ?? '';
          upcomingStops = (data['upcomingStops'] as List)
              .map((stop) => UpcomingStop.fromJson(stop))
              .toList();
          _tripStarted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip started successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // API Call: Get switching point location
  Future<void> _getSwitchingPointLocation() async {
    if (_switchingPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a switching point first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/${_switchingPointController.text}'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _showLocationOnMap(data);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _showLocationOnMap(Map<String, dynamic> locationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Switching Point Location"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locationData['name'] ?? _switchingPointController.text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        "Coordinates: ${locationData['latitude']}, ${locationData['longitude']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Helper method for headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': _jwtToken != null ? 'Bearer $_jwtToken' : '',
    };
  }

  void _loadLocationSuggestions() async {
    // This would be called when user types in search fields
    // Implement debouncing for better performance
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route View"),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (_jwtToken != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search fields section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _startPointController,
                          focusNode: _startPointFocus,
                          decoration: InputDecoration(
                            labelText: 'Starting Point',
                            prefixIcon: const Icon(Icons.my_location, color: Colors.blue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _endPointController,
                          focusNode: _endPointFocus,
                          decoration: InputDecoration(
                            labelText: 'Destination',
                            prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _showSwitchingPoint,
                              onChanged: (value) => setState(() => _showSwitchingPoint = value ?? false),
                            ),
                            const Text('Add Switching Point'),
                            const Spacer(),
                            if (_showSwitchingPoint)
                              IconButton(
                                icon: const Icon(Icons.map, color: Colors.blue),
                                onPressed: _getSwitchingPointLocation,
                              ),
                          ],
                        ),
                        if (_showSwitchingPoint) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _switchingPointController,
                            focusNode: _switchingPointFocus,
                            decoration: InputDecoration(
                              labelText: 'Switching Point',
                              prefixIcon: const Icon(Icons.transfer_within_a_station, color: Colors.blue),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text("Route Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRouteTypeOption(Icons.location_city, "City to City", 0),
                            _buildRouteTypeOption(Icons.park, "City to Village", 1),
                            _buildRouteTypeOption(Icons.directions_bus, "Intercity", 2),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: ElevatedButton(
                            onPressed: _planJourney,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Start Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rest of your UI remains the same...
                  if (_tripStarted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color.fromARGB(255, 25, 173, 210),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          _buildLocationRow(Icons.my_location, currentLocation),
                          const SizedBox(height: 8),
                          if (_showSwitchingPoint && switchingPoint.isNotEmpty) ...[
                            _buildLocationRow(Icons.transfer_within_a_station, switchingPoint),
                            const SizedBox(height: 8),
                          ],
                          _buildLocationRow(Icons.location_on, destination),
                        ],
                      ),
                    ),
                    Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, size: 50, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text("Map View", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text("Integration Required", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Upcoming Stops", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: upcomingStops.length,
                            itemBuilder: (context, index) => _buildStopItem(upcomingStops[index]),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "Enter your starting point and destination to plan your journey",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
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

  // Widget builders remain the same...
  Widget _buildRouteTypeOption(IconData icon, String title, int index) {
    final isSelected = _selectedRouteType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRouteType = index),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 30),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blue : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white))),
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
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: const Icon(Icons.location_pin, color: Color.fromARGB(255, 33, 201, 243), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(stop.name, style: const TextStyle(fontSize: 16))),
          Text(stop.time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700])),
        ],
      ),
    );
  }
}

class UpcomingStop {
  final String name;
  final String time;

  UpcomingStop({required this.name, required this.time});

  factory UpcomingStop.fromJson(Map<String, dynamic> json) {
    return UpcomingStop(
      name: json['name'],
      time: json['time'],
    );
  }
}

// DTO classes for API requests
class JourneyRequest {
  final String startPoint;
  final String endPoint;
  final String? switchingPoint;
  final int routeType;

  JourneyRequest({
    required this.startPoint,
    required this.endPoint,
    this.switchingPoint,
    required this.routeType,
  });

  Map<String, dynamic> toJson() => {
        'startPoint': startPoint,
        'endPoint': endPoint,
        'switchingPoint': switchingPoint,
        'routeType': routeType,
      };
}

class JourneyResponse {
  final String routeName;
  final String currentLocation;
  final String destination;
  final String? switchingPoint;
  final List<UpcomingStop> upcomingStops;

  JourneyResponse({
    required this.routeName,
    required this.currentLocation,
    required this.destination,
    this.switchingPoint,
    required this.upcomingStops,
  });

  factory JourneyResponse.fromJson(Map<String, dynamic> json) {
    return JourneyResponse(
      routeName: json['routeName'],
      currentLocation: json['currentLocation'],
      destination: json['destination'],
      switchingPoint: json['switchingPoint'],
      upcomingStops: (json['upcomingStops'] as List).map((e) => UpcomingStop.fromJson(e)).toList(),
    );
  }
}