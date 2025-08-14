import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';

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
  String _status = 'Ready to optimize your resume with AI!';
  bool _loading = false;
  Map<String, dynamic>? _analysisResult;
  final TextEditingController _jobDescController = TextEditingController();
  
  final String _apiUrl = 'http://localhost:8000';

  Future<void> _analyzeResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      setState(() {
        _loading = true;
        _status = 'Analyzing ${result.files.single.name} with AI...';
        _analysisResult = null;
      });

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_apiUrl/api/v1/resume/analyze'),
        );
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            result.files.single.bytes!,
            filename: result.files.single.name,
          ),
        );

        // Add job description if provided
        if (_jobDescController.text.isNotEmpty) {
          request.fields['job_description'] = _jobDescController.text;
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _analysisResult = data;
            _status = 'AI Analysis Complete!';
          });
        } else {
          setState(() {
            _status = 'Analysis failed: ${response.statusCode}';
          });
        }
      } catch (e) {
        setState(() {
          _status = 'Error: $e';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Section
            const Icon(
              Icons.psychology,
              size: 60,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              'AI-Powered Resume Optimization',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Job Description Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Description (Optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _jobDescController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Paste job description here for targeted optimization...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            if (_loading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI is analyzing your resume...'),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _analyzeResume,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload & Analyze Resume'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Analysis Results
            if (_analysisResult != null) ...[
              _buildAnalysisResults(_analysisResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults(Map<String, dynamic> result) {
    final resume = result['resume'] as Map<String, dynamic>?;
    final matchAnalysis = result['match_analysis'] as Map<String, dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resume Info Card
        if (resume != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Resume Parsed Successfully',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('📄 Filename: ${resume['filename']}'),
                  Text('📊 Word Count: ${resume['word_count']} words'),
                  if (resume['sections'] != null)
                    Text('📋 Sections Found: ${(resume['sections'] as Map).length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ATS Score Card
        if (matchAnalysis != null) ...[
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'ATS Compatibility Score',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 8.0,
                    percent: (matchAnalysis['ats_score'] as num) / 100,
                    center: Text(
                      '${matchAnalysis['ats_score']}%',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    progressColor: _getScoreColor(matchAnalysis['ats_score'] as num),
                  ),
                  const SizedBox(height: 16),
                  Text('Match: ${matchAnalysis['match_percentage']}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Skills Analysis
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('Matching Skills'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...((matchAnalysis['matching_tech_skills'] as List?) ?? [])
                            .map((skill) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('• $skill'),
                                )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text('Missing Skills'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...((matchAnalysis['missing_tech_skills'] as List?) ?? [])
                            .take(5)
                            .map((skill) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('• $skill'),
                                )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Suggestions
          Card(
            color: Colors.purple[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'AI Improvement Suggestions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...((matchAnalysis['suggestions'] as List?) ?? [])
                      .map((suggestion) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 '),
                                Expanded(child: Text(suggestion.toString())),
                              ],
                            ),
                          )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getScoreColor(num score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
