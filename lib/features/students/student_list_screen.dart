import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/custom_error_widget.dart';
import '../../shared/widgets/student_card.dart';
import 'student_provider.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort Student List',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Recently Added (Newest First)'),
                selected: provider.currentSort == StudentSortOption.dateNewest,
                onTap: () {
                  provider.setSortOption(StudentSortOption.dateNewest);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded),
                title: const Text('Name (A to Z)'),
                selected: provider.currentSort == StudentSortOption.nameAsc,
                onTap: () {
                  provider.setSortOption(StudentSortOption.nameAsc);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded),
                title: const Text('Name (Z to A)'),
                selected: provider.currentSort == StudentSortOption.nameDesc,
                onTap: () {
                  provider.setSortOption(StudentSortOption.nameDesc);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: const Text('GR Number (Ascending)'),
                selected: provider.currentSort == StudentSortOption.grAsc,
                onTap: () {
                  provider.setSortOption(StudentSortOption.grAsc);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentProvider = Provider.of<StudentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Options',
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                studentProvider.searchStudents(val);
              },
              decoration: InputDecoration(
                hintText: 'Search by Name, GR No, Mobile, Aadhaar...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          studentProvider.searchStudents('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Main Student List Content
          Expanded(
            child: studentProvider.isLoading
                ? const LoadingIndicatorWidget(message: 'Loading student directory...')
                : studentProvider.errorMessage != null
                    ? CustomErrorWidget(
                        errorMessage: studentProvider.errorMessage!,
                        onRetry: () => studentProvider.loadStudents(),
                      )
                    : studentProvider.students.isEmpty
                        ? EmptyStateWidget(
                            title: studentProvider.searchQuery.isNotEmpty
                                ? 'No matching students'
                                : 'No students found',
                            message: studentProvider.searchQuery.isNotEmpty
                                ? 'Try searching with a different name, GR number, or mobile.'
                                : 'Start by adding your first student record to EduVault.',
                            icon: Icons.school_outlined,
                            buttonText: studentProvider.searchQuery.isEmpty ? 'Add Student' : null,
                            onButtonPressed: () {
                              Navigator.pushNamed(context, Routes.addStudent);
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: () => studentProvider.loadStudents(),
                            child: ListView.builder(
                              itemCount: studentProvider.students.length,
                              padding: const EdgeInsets.only(bottom: 80, top: 8),
                              itemBuilder: (context, index) {
                                final student = studentProvider.students[index];
                                return StudentCard(
                                  student: student,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.studentProfile,
                                      arguments: student.id,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.addStudent);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Student'),
      ),
    );
  }
}
