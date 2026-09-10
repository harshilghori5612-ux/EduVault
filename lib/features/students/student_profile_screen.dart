import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/document_categories.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/student_model.dart';
import '../../shared/widgets/document_card.dart';
import 'student_provider.dart';
import '../documents/document_provider.dart';

class StudentProfileScreen extends StatefulWidget {
  final String studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentProvider>(context, listen: false)
          .loadDocumentsForStudent(widget.studentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteStudent(BuildContext context, StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Student Record?'),
          content: Text(
            'Are you sure you want to delete ${student.fullName}? '
            'This action will also permanently delete all associated documents.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<StudentProvider>(context, listen: false)
          .deleteStudent(student.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student deleted successfully.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.getStudentById(widget.studentId);
    final docProvider = Provider.of<DocumentProvider>(context);

    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(child: Text('Student not found')),
      );
    }

    final hasPhoto = student.photoPath != null && student.photoPath!.isNotEmpty;
    final docs = docProvider.studentDocuments;
    final completionRatio = docProvider.calculateCompletionPercentage(docs);
    final completionPct = (completionRatio * 100).toInt();

    final pendingCategories = docProvider.getPendingCategories(docs);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Student Details',
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                Routes.editStudent,
                arguments: student,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Student',
            onPressed: () => _confirmDeleteStudent(context, student),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Header Profile Banner
                  Hero(
                    tag: 'student_photo_${student.id}',
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: hasPhoto && File(student.photoPath!).existsSync()
                          ? FileImage(File(student.photoPath!))
                          : null,
                      child: !hasPhoto || !File(student.photoPath!).existsSync()
                          ? Text(
                              student.fullName.isNotEmpty
                                  ? student.fullName[0].toUpperCase()
                                  : 'S',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    student.fullName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(
                        label: Text('GR: ${student.grNumber}'),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${student.standard} - Div ${student.division}'),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Action Buttons Row for Profile
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.pushNamed(
                              context,
                              Routes.addDocument,
                              arguments: student.id,
                            );
                            docProvider.loadDocumentsForStudent(student.id);
                          },
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Add Document'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.pushNamed(
                              context,
                              Routes.documentScanner,
                              arguments: student.id,
                            );
                            docProvider.loadDocumentsForStudent(student.id);
                          },
                          icon: const Icon(Icons.document_scanner_rounded, size: 18),
                          label: const Text('Scan Doc'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab Bar Header
                  TabBar(
                    controller: _tabController,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(icon: Icon(Icons.person_outline), text: 'DETAILS'),
                      Tab(icon: Icon(Icons.folder_outlined), text: 'DOCUMENTS'),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: DETAILS
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection(
                    theme,
                    title: 'Student Information',
                    items: [
                      _DetailItem('Full Name', student.fullName),
                      _DetailItem('GR Number', student.grNumber),
                      _DetailItem('Aadhaar Number', student.aadhaarNumber ?? 'N/A'),
                      _DetailItem('Date of Birth', student.dateOfBirth),
                      _DetailItem('Gender', student.gender),
                      _DetailItem('Standard & Division', '${student.standard} (${student.division})'),
                      _DetailItem('Academic Year', student.academicYear),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailSection(
                    theme,
                    title: 'Parent Information',
                    items: [
                      _DetailItem('Father\'s Name', student.fatherName),
                      _DetailItem('Mother\'s Name', student.motherName),
                      _DetailItem('Parent Mobile', student.mobileNumber),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailSection(
                    theme,
                    title: 'Address & System Metadata',
                    items: [
                      _DetailItem('Full Address', student.address),
                      _DetailItem('Record Created', DateFormatter.formatIsoDate(student.createdAt)),
                      _DetailItem('Last Updated', DateFormatter.formatIsoDate(student.updatedAt)),
                    ],
                  ),
                ],
              ),
            ),

            // TAB 2: DOCUMENTS (Progress, Pending, Uploaded)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Document Completion Status',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$completionPct%',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: completionRatio,
                              minHeight: 10,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completionPct == 100 ? Colors.green : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploaded ${docs.length} of ${DocumentCategories.defaultList.length} possible categories',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Pending / Required Documents Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Documents (${pendingCategories.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: pendingCategories.isNotEmpty
                              ? theme.colorScheme.error
                              : Colors.green,
                        ),
                      ),
                      if (pendingCategories.isEmpty)
                        const Chip(
                          avatar: Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                          label: Text('All Complete', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          backgroundColor: Color(0xFFE8F5E9),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (pendingCategories.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingCategories.length,
                      itemBuilder: (context, index) {
                        final cat = pendingCategories[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.pending_actions_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Not uploaded yet',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      Routes.addDocument,
                                      arguments: {'studentId': student.id, 'category': cat},
                                    );
                                    docProvider.loadDocumentsForStudent(student.id);
                                  },
                                  icon: const Icon(Icons.upload_rounded, size: 16),
                                  label: const Text('Upload', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                                  tooltip: 'Scan $cat',
                                  onPressed: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      Routes.documentScanner,
                                      arguments: {'studentId': student.id, 'category': cat},
                                    );
                                    docProvider.loadDocumentsForStudent(student.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // 2. Uploaded Documents Section
                  Text(
                    'Uploaded Documents (${docs.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  docs.isEmpty
                      ? const EmptyStateWidget(
                          title: 'No Documents Uploaded',
                          message: 'Tap "+ Upload" or "Scan" above to upload certificates.',
                          icon: Icons.note_add_outlined,
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  Routes.documentViewer,
                                  arguments: doc,
                                );
                                docProvider.loadDocumentsForStudent(student.id);
                              },
                              onOpen: () async {
                                await Navigator.pushNamed(
                                  context,
                                  Routes.documentViewer,
                                  arguments: doc,
                                );
                                docProvider.loadDocumentsForStudent(student.id);
                              },
                              onReplace: () async {
                                await Navigator.pushNamed(
                                  context,
                                  Routes.documentViewer,
                                  arguments: doc,
                                );
                                docProvider.loadDocumentsForStudent(student.id);
                              },
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Document?'),
                                    content: Text('Delete "${doc.documentName}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await docProvider.deleteDocument(doc.id, student.id);
                                }
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    ThemeData theme, {
    required String title,
    required List<_DetailItem> items,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(height: 20),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
