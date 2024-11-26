import 'dart:convert';
import 'dart:io';

import 'package:assessment_mtss/screens/weather_details.dart';
import 'package:camera/camera.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _profilePicPath;
  bool _isFormFilled = false;

  Future<void> _saveData() async {
    final box = await Hive.openBox('registrationBox');
    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'password': _passwordController.text,
      'profilePic': _profilePicPath ?? '',
    };
    box.add(data);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherDetails(
          data: data,
        ),
      ),
      ModalRoute.withName('/'),
    );
    print('Registration Data Saved: $data');
  }

  Future<void> saveUserData(String name, String email, String phone) async {
    const url = 'http://127.0.0.1:5000/save_user';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"name": name, "email": email, "phone": phone}),
    );
    if (response.statusCode == 201) {
      print('User data saved: ${response.body}');
    } else {
      print('Failed to save user data: ${response.reasonPhrase}');
    }
  }

  Future<void> _takeSelfie() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeSelfieScreen(
          camera: firstCamera,
          onPictureTaken: (profilePic) {
            setState(() {
              _profilePicPath = profilePic.path;
            });
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    _nameController.addListener(_checkFormCompletion);
    _emailController.addListener(_checkFormCompletion);
    _phoneController.addListener(_checkFormCompletion);
    _passwordController.addListener(_checkFormCompletion);
    super.initState();
  }

  void _checkFormCompletion() {
    print('Name: ${_nameController.text}, '
        'Email: ${_emailController.text}, '
        'Phone: ${_phoneController.text}, '
        'Password: ${_passwordController.text}, '
        'Profile Picture: $_profilePicPath');
    setState(() {
      _isFormFilled = _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  int? selectedCardIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registration'),
          bottom: const TabBar(
            tabs: <Widget>[
              Text('New Registration'),
              Text('Already registered'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email')),
                  TextField(
                      controller: _phoneController,
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: const InputDecoration(labelText: 'Phone')),
                  TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _takeSelfie,
                    child: _profilePicPath != null
                        ? CircleAvatar(
                            radius: 48,
                            backgroundImage: FileImage(File(_profilePicPath!)),
                            backgroundColor: Colors.grey[200],
                          )
                        : const Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                child: Icon(Icons.person),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Icon(Icons.add),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isFormFilled
                        ? () {
                            saveUserData(_nameController.text,
                                _emailController.text, _phoneController.text);
                            _saveData();
                          }
                        : null,
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
            FutureBuilder(
              future: Hive.openBox('registrationBox'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No user registered'),
                  );
                }
                final box = snapshot.data as Box;
                final registrations = box.values.toList();

                if (registrations.isEmpty) {
                  return const Center(
                    child: Text('No registrations available'),
                  );
                }
                double newHeight = MediaQuery.of(context).size.height / 3;
                return Scaffold(
                  body: Column(
                    children: [
                      registrations.length > 1
                          ? CarouselSlider.builder(
                              carouselController: _carouselController,
                              itemCount: registrations.length,
                              itemBuilder: (context, index, realIndex) {
                                final data = registrations[index];
                                return _buildRegistrationCard(data, index);
                              },
                              options: CarouselOptions(
                                initialPage: _currentIndex,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                                height: newHeight,
                                viewportFraction: 0.8,
                                enableInfiniteScroll: false,
                                enlargeCenterPage: true,
                              ),
                            )
                          : _buildRegistrationCard(registrations.first, 0),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedCardIndex != -1) {
                            final selectedData =
                                registrations[selectedCardIndex!];
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WeatherDetails(data: selectedData),
                              ),
                              ModalRoute.withName('/'),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a user first!')),
                            );
                          }
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(Map<dynamic, dynamic> data, int index) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCardIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selectedCardIndex == index
                ? Colors.lightBlue
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              data['profilePic'] != null
                  ? CircleAvatar(
                      radius: 48,
                      backgroundImage: FileImage(File(data['profilePic'])),
                      backgroundColor: Colors.grey[200],
                    )
                  : const CircleAvatar(
                      radius: 48,
                      child: Icon(Icons.person),
                    ),
              const SizedBox(height: 16),
              Text(
                'Name: ${data['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Email: ${data['email']}'),
              Text('Phone: ${data['phone']}'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class TakeSelfieScreen extends StatefulWidget {
  final void Function(XFile profilePic) onPictureTaken;
  const TakeSelfieScreen({
    super.key,
    required this.camera,
    required this.onPictureTaken,
  });

  final CameraDescription camera;

  @override
  TakeSelfieScreenState createState() => TakeSelfieScreenState();
}

class TakeSelfieScreenState extends State<TakeSelfieScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera screen"),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final XFile image = await _controller.takePicture();
            if (!context.mounted) return;
            widget.onPictureTaken(image);
            Navigator.pop(context, image);
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
