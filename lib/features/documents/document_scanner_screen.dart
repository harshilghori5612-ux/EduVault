import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/constants/document_categories.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/student_model.dart';
import '../students/student_provider.dart';
import 'document_provider.dart';

class DocumentScannerScreen extends StatefulWidget {
  final String? initialStudentId;
  final String? initialCategory;

  const DocumentScannerScreen({
    super.key,
    this.initialStudentId,
    this.initialCategory,
  });

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  final _documentNameController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedStudentId;
  late String _selectedCategory;
  String? _capturedImagePath;
  bool _isCameraPermissionGranted = false;
  bool _checkingPermission = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    _selectedCategory = widget.initialCategory ?? DocumentCategories.defaultList.first;
    _documentNameController.text = _selectedCategory;
    _checkCameraPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudentProvider>(context, listen: false);
      if (provider.allStudents.isEmpty) {
        provider.loadStudents();
      }
    });
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    setState(() => _checkingPermission = true);
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _isCameraPermissionGranted = true;
        _checkingPermission = false;
      });
    } else {
      final requestStatus = await Permission.camera.request();
      setState(() {
        _isCameraPermissionGranted = requestStatus.isGranted;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _captureDocumentPhoto() async {
    if (!_isCameraPermissionGranted) {
      await _checkCameraPermission();
      if (!_isCameraPermissionGranted) return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
      );

      if (photo != null) {
        setState(() {
          _capturedImagePath = photo.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera capture error: $e')),
        );
      }
    }
  }

  Future<void> _saveScannedDocument() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }
    if (_capturedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture a document photo')),
      );
      return;
    }

    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    final savedDoc = await docProvider.saveDocumentFile(
      studentId: _selectedStudentId!,
      documentName: _documentNameController.text.trim(),
      category: _selectedCategory,
      sourceFilePath: _capturedImagePath!,
      fileType: 'image',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      if (savedDoc != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanned document saved to vault!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, savedDoc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(docProvider.errorMessage ?? 'Failed to save scanned document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final students = Provider.of<StudentProvider>(context).allStudents;
    final docProvider = Provider.of<DocumentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
      ),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select Student
                  Text(
                    'Step 1: Select Student',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CustomDropdownField<String>(
                    value: students.any((s) => s.id == _selectedStudentId) ? _selectedStudentId : null,
                    labelText: 'Student *',
                    prefixIcon: Icons.person_outlined,
                    items: students.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.fullName} (GR: ${s.grNumber})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStudentId = val),
                  ),
                  const SizedBox(height: 18),

                  // Step 2: Select Document Category
                  Text(
                    'Step 2: Select Category',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CustomDropdownField<String>(
                    value: _selectedCategory,
                    labelText: 'Category *',
                    prefixIcon: Icons.category_outlined,
                    items: DocumentCategories.defaultList
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                          _documentNameController.text = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  CustomTextField(
                    controller: _documentNameController,
                    labelText: 'Document Title *',
                    prefixIcon: Icons.title_outlined,
                  ),
                  const SizedBox(height: 24),

                  // Step 3: Capture Camera Image Preview Area
                  Text(
                    'Step 3: Capture & Preview Document',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  !_isCameraPermissionGranted
                      ? Card(
                          color: theme.colorScheme.errorContainer.withOpacity(0.4),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(Icons.camera_enhance_outlined, size: 48, color: theme.colorScheme.error),
                                const SizedBox(height: 12),
                                Text(
                                  'Camera Permission Required',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Camera access is required to scan physical student documents.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: openAppSettings,
                                  child: const Text('Open App Settings'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _capturedImagePath == null
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.document_scanner_rounded, size: 64, color: theme.colorScheme.primary),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Ready to Scan Document',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Align student certificate inside lighting and tap capture.',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _captureDocumentPhoto,
                                    icon: const Icon(Icons.camera_alt_rounded),
                                    label: const Text('Open Camera Scanner'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_capturedImagePath!),
                                        height: 240,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _captureDocumentPhoto,
                                          icon: const Icon(Icons.refresh_rounded),
                                          label: const Text('Retake Scan'),
                                        ),
                                        Text(
                                          'Scan Preview OK',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                  const SizedBox(height: 20),

                  // Optional Notes
                  CustomTextField(
                    controller: _notesController,
                    labelText: 'Scanner Notes (Optional)',
                    prefixIcon: Icons.note_alt_outlined,
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  CustomButton(
                    text: 'Save Scanned Document',
                    icon: Icons.check_circle_rounded,
                    isLoading: docProvider.isLoading,
                    onPressed: _saveScannedDocument,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
