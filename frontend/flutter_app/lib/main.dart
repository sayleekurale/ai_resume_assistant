import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Resume Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'Ready to optimize your resume!';
  bool _loading = false;
  
  final String _apiUrl = 'http://localhost:8000'; // Your backend URL

  Future<void> _checkBackendConnection() async {
    setState(() {
      _loading = true;
      _status = 'Connecting to AI backend...';
    });

    try {
      final response = await http.get(Uri.parse('$_apiUrl/health'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = 'Connected! Backend status: ${data['status']}';
        });
      } else {
        setState(() {
          _status = 'Backend connection failed: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e\nMake sure backend is running on port 8000';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      setState(() {
        _loading = true;
        _status = 'Uploading ${result.files.single.name}...';
      });

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_apiUrl/api/v1/resume/upload'),
        );
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            result.files.single.bytes!,
            filename: result.files.single.name,
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _status = 'Success! Uploaded: ${data['filename']}\n${data['message']}';
          });
        } else {
          setState(() {
            _status = 'Upload failed: ${response.statusCode}';
          });
        }
      } catch (e) {
        setState(() {
          _status = 'Upload error: $e';
        });
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'AI-Powered Resume Optimization',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_loading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _checkBackendConnection,
                    icon: const Icon(Icons.wifi),
                    label: const Text('Test Backend Connection'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _uploadResume,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Resume'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
