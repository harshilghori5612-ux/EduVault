import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../data/models/document_model.dart';
import '../students/student_provider.dart';
import 'document_provider.dart';

class DocumentViewerScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late DocumentModel _doc;
  bool _isReplacing = false;

  @override
  void initState() {
    super.initState();
    _doc = widget.document;
  }

  Future<void> _openWithSystemApp() async {
    final file = File(_doc.filePath);
    if (await file.exists()) {
      final result = await OpenFile.open(_doc.filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found on device storage')),
        );
      }
    }
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${_doc.documentName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final docProvider = Provider.of<DocumentProvider>(context, listen: false);
      final success = await docProvider.deleteDocument(_doc.id, _doc.studentId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _replaceDocument() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Replace Document File',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.camera_alt_rounded)),
                title: const Text('Capture New Photo (Camera)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (img != null) _performFileReplacement(img.path, 'image');
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.photo_library_rounded)),
                title: const Text('Select from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (img != null) _performFileReplacement(img.path, 'image');
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.picture_as_pdf_rounded)),
                title: const Text('Select PDF from Device'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null && result.files.single.path != null) {
                    _performFileReplacement(result.files.single.path!, 'pdf');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performFileReplacement(String newPath, String fileType) async {
    setState(() => _isReplacing = true);
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    final updated = await docProvider.replaceDocumentFile(
      oldDocument: _doc,
      newSourceFilePath: newPath,
      newFileType: fileType,
    );
    if (mounted) {
      setState(() => _isReplacing = false);
      if (updated != null) {
        setState(() {
          _doc = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document replaced successfully.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(docProvider.errorMessage ?? 'Failed to replace document')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = Provider.of<StudentProvider>(context).getStudentById(_doc.studentId);
    final file = File(_doc.filePath);
    final fileExists = file.existsSync();
    final isPdf = _doc.fileType.toLowerCase().contains('pdf') || _doc.filePath.endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        title: Text(_doc.documentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Replace File',
            onPressed: _replaceDocument,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open with External App',
            onPressed: _openWithSystemApp,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Document',
            onPressed: _deleteDocument,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Container
            Container(
              width: double.infinity,
              height: 340,
              decoration: BoxDecoration(
                color: isPdf
                    ? Colors.red.shade50
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              child: fileExists
                  ? !isPdf
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            child: Image.file(
                              file,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 80, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _doc.documentName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _openWithSystemApp,
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open PDF Document'),
                            ),
                          ],
                        )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 56, color: Colors.red),
                          SizedBox(height: 12),
                          Text('File not found on local storage'),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Metadata Card
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildMetaRow(theme, 'Category', _doc.category),
                    _buildMetaRow(theme, 'Associated Student', student?.fullName ?? _doc.studentId),
                    _buildMetaRow(theme, 'GR Number', student?.grNumber ?? 'N/A'),
                    _buildMetaRow(theme, 'File Format', _doc.fileType.toUpperCase()),
                    _buildMetaRow(theme, 'Upload Date', DateFormatter.formatIsoDate(_doc.uploadedAt)),
                    if (_doc.notes != null && _doc.notes!.isNotEmpty)
                      _buildMetaRow(theme, 'Notes', _doc.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isReplacing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isReplacing ? null : _replaceDocument,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Replace File'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openWithSystemApp,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open File'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
