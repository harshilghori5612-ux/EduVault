import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/student_model.dart';
import 'student_provider.dart';

class EditStudentScreen extends StatefulWidget {
  final StudentModel student;

  const EditStudentScreen({super.key, required this.student});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _grNumberController;
  late TextEditingController _aadhaarController;
  late TextEditingController _dobController;
  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;

  String? _selectedGender;
  String? _selectedStandard;
  String? _selectedDivision;
  String? _selectedAcademicYear;
  String? _photoPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _fullNameController = TextEditingController(text: s.fullName);
    _grNumberController = TextEditingController(text: s.grNumber);
    _aadhaarController = TextEditingController(text: s.aadhaarNumber ?? '');
    _dobController = TextEditingController(text: s.dateOfBirth);
    _fatherNameController = TextEditingController(text: s.fatherName);
    _motherNameController = TextEditingController(text: s.motherName);
    _mobileController = TextEditingController(text: s.mobileNumber);
    _addressController = TextEditingController(text: s.address);

    _selectedGender = AppConstants.genders.contains(s.gender) ? s.gender : AppConstants.genders.first;
    _selectedStandard = AppConstants.standards.contains(s.standard) ? s.standard : AppConstants.standards.first;
    _selectedDivision = AppConstants.divisions.contains(s.division) ? s.division : AppConstants.divisions.first;
    _selectedAcademicYear = AppConstants.academicYears.contains(s.academicYear) ? s.academicYear : AppConstants.academicYears.last;
    _photoPath = s.photoPath;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _grNumberController.dispose();
    _aadhaarController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _photoPath = pickedFile.path;
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

  void _showPhotoOptions() {
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
                  'Change Student Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Take Photo using Camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Select Photo from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_photoPath != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _photoPath = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initial = DateFormatter.parseDate(_dobController.text) ?? DateTime(now.year - 8);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormatter.formatDate(pickedDate);
      });
    }
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedStudent = widget.student.copyWith(
      fullName: _fullNameController.text.trim(),
      grNumber: _grNumberController.text.trim(),
      aadhaarNumber: _aadhaarController.text.trim().isEmpty ? null : _aadhaarController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      gender: _selectedGender!,
      standard: _selectedStandard!,
      division: _selectedDivision!,
      academicYear: _selectedAcademicYear!,
      fatherName: _fatherNameController.text.trim(),
      motherName: _motherNameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      photoPath: _photoPath,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final provider = Provider.of<StudentProvider>(context, listen: false);
    final success = await provider.updateStudent(updatedStudent);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedStudent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update student'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<StudentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Student Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Avatar Picker
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: _photoPath != null && File(_photoPath!).existsSync()
                          ? FileImage(File(_photoPath!))
                          : null,
                      child: _photoPath == null
                          ? Icon(
                              Icons.add_a_photo_rounded,
                              size: 36,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change photo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Student Information
              _buildSectionHeader(theme, '1. Student Information', Icons.person_rounded),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _fullNameController,
                labelText: 'Full Name *',
                prefixIcon: Icons.badge_outlined,
                validator: (val) => Validators.required(val, 'Full Name'),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _grNumberController,
                      labelText: 'GR Number *',
                      prefixIcon: Icons.numbers_outlined,
                      validator: (val) => Validators.grNumber(val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _aadhaarController,
                      labelText: 'Aadhaar Number',
                      prefixIcon: Icons.credit_card_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) => Validators.aadhaar(val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _dobController,
                      labelText: 'Date of Birth *',
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (val) => Validators.required(val, 'Date of Birth'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomDropdownField<String>(
                      value: _selectedGender,
                      labelText: 'Gender *',
                      prefixIcon: Icons.wc_outlined,
                      items: AppConstants.genders
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomDropdownField<String>(
                      value: _selectedStandard,
                      labelText: 'Standard *',
                      prefixIcon: Icons.class_outlined,
                      items: AppConstants.standards
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStandard = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomDropdownField<String>(
                      value: _selectedDivision,
                      labelText: 'Division *',
                      prefixIcon: Icons.grid_view_outlined,
                      items: AppConstants.divisions
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedDivision = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomDropdownField<String>(
                value: _selectedAcademicYear,
                labelText: 'Academic Year *',
                prefixIcon: Icons.date_range_outlined,
                items: AppConstants.academicYears
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedAcademicYear = val),
              ),
              const SizedBox(height: 28),

              // Section 2: Parent Information
              _buildSectionHeader(theme, '2. Parent Information', Icons.family_restroom_rounded),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _fatherNameController,
                labelText: 'Father\'s Name *',
                prefixIcon: Icons.man_outlined,
                validator: (val) => Validators.required(val, 'Father\'s Name'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _motherNameController,
                labelText: 'Mother\'s Name *',
                prefixIcon: Icons.woman_outlined,
                validator: (val) => Validators.required(val, 'Mother\'s Name'),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _mobileController,
                labelText: 'Parent Mobile Number *',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) => Validators.mobile(val),
              ),
              const SizedBox(height: 28),

              // Section 3: Address
              _buildSectionHeader(theme, '3. Address', Icons.home_outlined),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _addressController,
                labelText: 'Full Address *',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (val) => Validators.required(val, 'Address'),
              ),
              const SizedBox(height: 32),

              // Update Button
              CustomButton(
                text: 'Update Student Changes',
                icon: Icons.check_circle_outline_rounded,
                isLoading: provider.isLoading,
                onPressed: _updateStudent,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
