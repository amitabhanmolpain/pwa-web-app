import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dashboard_screen.dart';

class SetupProfileDocumentsScreen extends StatefulWidget {
  const SetupProfileDocumentsScreen({super.key});

  @override
  State<SetupProfileDocumentsScreen> createState() => _SetupProfileDocumentsScreenState();
}

class _SetupProfileDocumentsScreenState extends State<SetupProfileDocumentsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, File?> _selectedDocuments = {
    'drivingLicense': null,
    'vehicleRegistration': null,
    'insuranceCertificate': null,
  };
  Map<String, String> _documentUrls = {
    'drivingLicense': '',
    'vehicleRegistration': '',
    'insuranceCertificate': '',
  };

  // API endpoints
  static const String BASE_URL = 'http://your-spring-boot-server:8080/api';
  static const String DOCUMENTS_ENDPOINT = '$BASE_URL/driver/documents';
  static const String UPLOAD_DOCUMENT_ENDPOINT = '$BASE_URL/driver/documents/upload';
  static const String COMPLETE_PROFILE_ENDPOINT = '$BASE_URL/driver/profile/complete';

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
  }

  // Load existing document data
  Future<void> _loadDocumentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      final response = await http.get(
        Uri.parse(DOCUMENTS_ENDPOINT),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final documentsData = json.decode(response.body);
        setState(() {
          _documentUrls = {
            'drivingLicense': documentsData['drivingLicenseUrl'] ?? '',
            'vehicleRegistration': documentsData['vehicleRegistrationUrl'] ?? '',
            'insuranceCertificate': documentsData['insuranceCertificateUrl'] ?? '',
          };
        });
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _loadDocumentData();
          return;
        }
      }
      // If 404, it means no documents exist yet - that's fine

    } catch (error) {
      print('Error loading documents: $error');
      // Silently fail - user can upload new documents
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Pick document from gallery or camera
  Future<void> _pickDocument(String documentType) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedDocuments[documentType] = File(pickedFile.path);
        });
        await _uploadDocument(documentType);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload document to backend
  Future<void> _uploadDocument(String documentType) async {
    final file = _selectedDocuments[documentType];
    if (file == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(UPLOAD_DOCUMENT_ENDPOINT),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add document file
      request.files.add(await http.MultipartFile.fromPath(
        'document',
        file.path,
        filename: '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      // Add document type
      request.fields['documentType'] = documentType;

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _documentUrls[documentType] = jsonResponse['documentUrl'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getDocumentName(documentType)} uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to upload document: ${jsonResponse['message']}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading document: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Complete profile setup
  Future<void> _completeProfileSetup() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      // Check if all required documents are uploaded
      final missingDocuments = _documentUrls.entries
          .where((entry) => entry.value.isEmpty)
          .map((entry) => _getDocumentName(entry.key))
          .toList();

      if (missingDocuments.isNotEmpty) {
        throw Exception('Please upload all required documents: ${missingDocuments.join(", ")}');
      }

      final response = await http.post(
        Uri.parse(COMPLETE_PROFILE_ENDPOINT),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'drivingLicenseUrl': _documentUrls['drivingLicense'],
          'vehicleRegistrationUrl': _documentUrls['vehicleRegistration'],
          'insuranceCertificateUrl': _documentUrls['insuranceCertificate'],
          'profileComplete': true,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Profile setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _completeProfileSetup();
          return;
        }
      } else {
        throw Exception('Failed to complete profile: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing profile: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Refresh JWT token
  Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$BASE_URL/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newAccessToken = responseData['accessToken'];
        await prefs.setString('access_token', newAccessToken);
        return newAccessToken;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return null;
  }

  String _getDocumentName(String documentType) {
    switch (documentType) {
      case 'drivingLicense':
        return 'Driving License';
      case 'vehicleRegistration':
        return 'Vehicle Registration';
      case 'insuranceCertificate':
        return 'Insurance Certificate';
      default:
        return 'Document';
    }
  }

  String _getDocumentKey(String title) {
    switch (title) {
      case 'Upload Driving License':
        return 'drivingLicense';
      case 'Upload Vehicle Registration':
        return 'vehicleRegistration';
      case 'Upload Insurance Certificate':
        return 'insuranceCertificate';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Steps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStep(1, 'Personal', false),
                      _buildStep(2, 'Vehicle', false),
                      _buildStep(3, 'Documents', true),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Document Upload Sections
                  _buildDocumentUpload('Upload Driving License', 'drivingLicense'),
                  const SizedBox(height: 16),
                  
                  _buildDocumentUpload('Upload Vehicle Registration', 'vehicleRegistration'),
                  const SizedBox(height: 16),
                  
                  _buildDocumentUpload('Upload Insurance Certificate', 'insuranceCertificate'),
                  const SizedBox(height: 32),
                  
                  // Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _completeProfileSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save & Complete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStep(int number, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF6366F1) : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUpload(String title, String documentType) {
    final hasFile = _selectedDocuments[documentType] != null;
    final hasUrl = _documentUrls[documentType]?.isNotEmpty ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            
            if (hasFile || hasUrl)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasFile ? 'Document selected' : 'Document uploaded',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Document required', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _pickDocument(documentType),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Choose File'),
            ),
          ],
        ),
      ),
    );
  }
}