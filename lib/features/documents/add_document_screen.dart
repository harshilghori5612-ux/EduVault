import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/document_categories.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/student_model.dart';
import '../students/student_provider.dart';
import 'document_provider.dart';

class AddDocumentScreen extends StatefulWidget {
  final String? initialStudentId;
  final String? initialCategory;

  const AddDocumentScreen({
    super.key,
    this.initialStudentId,
    this.initialCategory,
  });

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNameController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedStudentId;
  late String _selectedCategory;

  String? _selectedFilePath;
  String? _fileType; // 'image' or 'pdf'

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    _selectedCategory = widget.initialCategory ?? DocumentCategories.defaultList.first;
    _documentNameController.text = _selectedCategory;
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image != null) {
        setState(() {
          _selectedFilePath = image.path;
          _fileType = 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _fileType = 'pdf';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select PDF: $e')),
        );
      }
    }
  }

  void _showSourceSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Document Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.document_scanner_rounded, color: Colors.blue),
                  title: const Text('Scan using Camera Scanner'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (_selectedStudentId != null) {
                      await Navigator.pushNamed(
                        context,
                        Routes.documentScanner,
                        arguments: _selectedStudentId,
                      );
                      if (mounted) Navigator.pop(context);
                    } else {
                      _pickImage(ImageSource.camera);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Colors.teal),
                  title: const Text('Capture Quick Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Colors.amber),
                  title: const Text('Select Image from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                  title: const Text('Select PDF Document from Device'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPdf();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or select a document file')),
      );
      return;
    }

    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    final savedDoc = await docProvider.saveDocumentFile(
      studentId: _selectedStudentId!,
      documentName: _documentNameController.text.trim(),
      category: _selectedCategory,
      sourceFilePath: _selectedFilePath!,
      fileType: _fileType ?? 'image',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      if (savedDoc != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, savedDoc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(docProvider.errorMessage ?? 'Failed to save document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context);
    final students = studentProvider.allStudents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Select Student Dropdown
              Text(
                'Select Student',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CustomDropdownField<String>(
                value: students.any((s) => s.id == _selectedStudentId) ? _selectedStudentId : null,
                labelText: 'Student *',
                prefixIcon: Icons.person_search_outlined,
                items: students.map((s) {
                  return DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.fullName} (GR: ${s.grNumber})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedStudentId = val;
                  });
                },
                validator: (val) => val == null ? 'Please select a student' : null,
              ),
              const SizedBox(height: 20),

              // 2. Select Document Category
              Text(
                'Document Category',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CustomDropdownField<String>(
                value: _selectedCategory,
                labelText: 'Category *',
                prefixIcon: Icons.category_outlined,
                items: DocumentCategories.defaultList.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                      _documentNameController.text = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // 3. Document Display Name
              CustomTextField(
                controller: _documentNameController,
                labelText: 'Document Name *',
                prefixIcon: Icons.title_outlined,
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter document name' : null,
              ),
              const SizedBox(height: 24),

              // 4. File Source Selection & Preview Area
              Text(
                'File Attachment',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _selectedFilePath == null
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'No document selected yet',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capture via camera or pick image/PDF from your device',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showSourceSelectionSheet,
                            icon: const Icon(Icons.attach_file_rounded),
                            label: const Text('Choose Document'),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _fileType == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                  color: _fileType == 'pdf' ? Colors.red : theme.colorScheme.primary,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFilePath!.split(Platform.pathSeparator).last,
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Type: ${_fileType?.toUpperCase() ?? "FILE"}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz_rounded),
                                  tooltip: 'Replace File',
                                  onPressed: _showSourceSelectionSheet,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                                  tooltip: 'Remove',
                                  onPressed: () {
                                    setState(() {
                                      _selectedFilePath = null;
                                      _fileType = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_fileType == 'image' && File(_selectedFilePath!).existsSync()) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_selectedFilePath!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 20),

              // 5. Additional Notes Field
              CustomTextField(
                controller: _notesController,
                labelText: 'Notes (Optional)',
                hintText: 'e.g. Verified original mark sheet',
                prefixIcon: Icons.note_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: 'Save Document',
                icon: Icons.save_rounded,
                isLoading: docProvider.isLoading,
                onPressed: _saveDocument,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
