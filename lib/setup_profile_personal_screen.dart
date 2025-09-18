import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'setup_profile_vehicle_screen.dart';

class SetupProfilePersonalScreen extends StatefulWidget {
  const SetupProfilePersonalScreen({super.key});

  @override
  State<SetupProfilePersonalScreen> createState() =>
      _SetupProfilePersonalScreenState();
}

class _SetupProfilePersonalScreenState
    extends State<SetupProfilePersonalScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _profilePhotoUrl;
  final ImagePicker _imagePicker = ImagePicker();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // API endpoints (replace with your .env values if using dotenv)
  static const String BASE_URL = 'http://localhost:8080/api';
  static const String USER_ENDPOINT = '$BASE_URL/user';
  static const String UPLOAD_PHOTO_ENDPOINT = '$BASE_URL/user/photo';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Load existing profile data
Future<void> _loadProfileData() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final userId = await _secureStorage.read(key: 'user_id');

    if (accessToken == null || userId == null) {
      throw Exception('Not authenticated. Please login again.');
    }

    // Try fetch by explicit ID, fallback to authenticated endpoint
    http.Response response = await http.get(
      Uri.parse('$USER_ENDPOINT/$userId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    // If unauthorized, prompt relogin (no refresh token flow configured here)

    if (response.statusCode == 404 || response.statusCode == 400) {
      // Fallback to current authenticated user if ID-based fetch fails
      response = await http.get(
        Uri.parse(USER_ENDPOINT),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
    }

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final Map<String, dynamic> userData =
          decoded is Map<String, dynamic> && decoded.containsKey('user')
              ? Map<String, dynamic>.from(decoded['user'] ?? {})
              : Map<String, dynamic>.from(decoded ?? {});

      setState(() {
        _nameController.text = (userData['name'] ?? '').toString();
        _phoneController.text = (userData['phone'] ?? '').toString();
        _emailController.text = (userData['email'] ?? '').toString();
        _addressController.text = (userData['address'] ?? '').toString();
        _profilePhotoUrl = userData['profileImageUrl'] as String?;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile (${response.statusCode})'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (error) {
    print('Error loading profile: $error');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}




  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _selectedImageBytes = null;
          });
        }
        await _uploadPhoto();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Capture image from camera
  Future<void> _captureImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _selectedImageBytes = null;
          });
        }
        await _uploadPhoto();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Upload profile photo
  Future<void> _uploadPhoto() async {
    if (_selectedImage == null && _selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await _secureStorage.read(key: 'access_token');

      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(UPLOAD_PHOTO_ENDPOINT),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['Accept'] = 'application/json';

      if (_selectedImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          _selectedImageBytes!,
          filename: 'profile_photo.jpg',
        ));
      } else if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _selectedImage!.path,
          filename: 'profile_photo.jpg',
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _profilePhotoUrl = jsonResponse['photoUrl'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to upload photo: ${jsonResponse['message']}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final userId = await _secureStorage.read(key: 'user_id');

      if (accessToken == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      if (userId == null) {
        throw Exception('Missing user id.');
      }

      final response = await http.put(
        Uri.parse('$USER_ENDPOINT/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(), // ✅ fixed
          'address': _addressController.text.trim(),
          'profileImageUrl': _profilePhotoUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const SetupProfileVehicleScreen()),
        );
      } else if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          await _saveProfile();
          return;
        }
      } else {
        throw Exception('Failed to save profile: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $error'), // ✅ fixed
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // No refresh token flow set up; require re-login on 401
  Future<String?> _refreshToken() async => null;

  // Validation
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your address';
    }
    if (value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Steps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStep(1, 'Personal', true),
                        _buildStep(2, 'Vehicle', false),
                        _buildStep(3, 'Documents', false),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Profile Photo Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.grey[300]!, width: 2),
                                  image: _selectedImageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(_selectedImageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : _selectedImage != null
                                          ? DecorationImage(
                                              image: FileImage(_selectedImage!),
                                              fit: BoxFit.cover,
                                            )
                                      : _profilePhotoUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                  _profilePhotoUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: _selectedImage == null &&
                                        _profilePhotoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              if (_isLoading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed:
                                _isLoading ? null : _showImageSourceDialog,
                            child: const Text(
                              'Change Photo',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Form Fields
                    _buildFormField(
                      'Full Name',
                      '',
                      _nameController,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      'Phone Number',
                      '',
                      _phoneController,
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      'Email',
                      '',
                      _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      'Address',
                      '',
                      _addressController,
                      validator: _validateAddress,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  Widget _buildFormField(
    String label,
    String hint,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
