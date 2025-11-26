import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/widgets/custom_textfield.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class ProjectForm extends StatefulWidget {
  final Project? initialProject;
  const ProjectForm({super.key, this.initialProject});

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _projectController = Get.find<ProjectController>();

  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _genotypeController = TextEditingController();
  final _notesController = TextEditingController();
  final _plantingDateController = TextEditingController();
  final _harvestDateController = TextEditingController();

  DateTime? _plantingDate;
  DateTime? _harvestDate;

  bool get _isEditing => widget.initialProject != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProject;
    if (initial != null) {
      _projectNameController.text = initial.projectName;
      _descriptionController.text = initial.description;
      _genotypeController.text = initial.genotypeName;
      _notesController.text = initial.notes ?? '';
      _plantingDate = initial.plantingDate;
      _harvestDate = initial.harvestDate;
      if (_plantingDate != null) {
        _plantingDateController.text = _formatDate(_plantingDate!);
      }
      if (_harvestDate != null) {
        _harvestDateController.text = _formatDate(_harvestDate!);
      }
    } else {
      _projectNameController.text = _projectController.projectName ?? '';
      _descriptionController.text = _projectController.projectDescription ?? '';
      _genotypeController.text = '';
      _notesController.text = '';
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    _genotypeController.dispose();
    _notesController.dispose();
    _plantingDateController.dispose();
    _harvestDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({
    required bool isPlantingDate,
  }) async {
    final currentValue = isPlantingDate ? _plantingDate : _harvestDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isPlantingDate) {
        _plantingDate = picked;
        _plantingDateController.text = _formatDate(picked);
      } else {
        _harvestDate = picked;
        _harvestDateController.text = _formatDate(picked);
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSubmit() async {
    final name = _projectNameController.text.trim();
    final description = _descriptionController.text.trim();
    final genotype = _genotypeController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty) {
      return _showError('Please enter your project name');
    }
    if (description.isEmpty) {
      return _showError('Please enter your project description');
    }
    if (genotype.isEmpty) {
      return _showError('Please enter genotype name');
    }
    if (_plantingDate != null &&
        _harvestDate != null &&
        _harvestDate!.isBefore(_plantingDate!)) {
      return _showError('Harvest date cannot be earlier than planting date');
    }

    final payloadNotes = notes.isEmpty ? null : notes;

    if (_isEditing) {
      final existing = widget.initialProject!;
      final updatedProject = existing.copyWith(
        projectName: name,
        genotypeName: genotype,
        description: description,
        plantingDate: _plantingDate,
        harvestDate: _harvestDate,
        notes: payloadNotes,
        updatedAt: DateTime.now(),
      );

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        final result = await _projectController.updateProject(updatedProject);
        Get.back();

        if (result.success) {
          Get.snackbar(
            'Success',
            'Project updated successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.back(result: true);
        } else {
          _showError(result.message);
        }
      } catch (e) {
        Get.back();
        _showError('An unexpected error occurred. Please try again.');
      }
    } else {
      final newProject = Project(
        id: '',
        projectName: name,
        genotypeName: genotype,
        description: description,
        plantingDate: _plantingDate,
        harvestDate: _harvestDate,
        notes: payloadNotes,
        status: ProjectStatus.active,
        createdAt: DateTime.now(),
        isBookmark: false,
        images: const [],
        analyses: const [],
      );

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        final result = await _projectController.createProject(newProject);
        Get.back();

        if (result.success) {
          _clearForm();
          Get.snackbar(
            'Success',
            'Project created successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.back(result: true);
        } else {
          _showError(result.message);
        }
      } catch (e) {
        Get.back();
        _showError('An unexpected error occurred. Please try again.');
      }
    }
  }

  void _clearForm() {
    _projectNameController.clear();
    _descriptionController.clear();
    _genotypeController.clear();
    _notesController.clear();
    _plantingDateController.clear();
    _harvestDateController.clear();
    _plantingDate = null;
    _harvestDate = null;
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildField({required Widget child}) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildField(
            child: CustomTextfield(
              label: 'Project Name',
              prefixIcon: Icons.title_outlined,
              controller: _projectNameController,
            ),
          ),
          const SizedBox(height: 16),
          buildField(
            child: CustomTextfield(
              label: 'Genotype Name',
              prefixIcon: Icons.rice_bowl,
              controller: _genotypeController,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildField(
                  child: CustomTextfield(
                    label: 'Planting Date',
                    prefixIcon: Icons.event_available_outlined,
                    controller: _plantingDateController,
                    readOnly: true,
                    onTap: () => _selectDate(isPlantingDate: true),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildField(
                  child: CustomTextfield(
                    label: 'Harvest Date',
                    prefixIcon: Icons.event_note_outlined,
                    controller: _harvestDateController,
                    readOnly: true,
                    onTap: () => _selectDate(isPlantingDate: false),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildField(
            child: CustomTextfield(
              label: 'Description',
              prefixIcon: Icons.description_outlined,
              controller: _descriptionController,
              keyboardType: TextInputType.multiline,
              maxLines: 10,
              minLines: 5,
            ),
          ),
                    const SizedBox(height: 16),
          buildField(
            child: CustomTextfield(
              label: 'Notes (optional)',
              prefixIcon: Icons.notes_outlined,
              controller: _notesController,
              keyboardType: TextInputType.multiline,
              maxLines: 4,
              minLines: 2,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEditing ? 'Save Changes' : 'Create Project',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
