
import 'package:flutter/material.dart';
import '../../core/api_service.dart';

class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  State<CitizenProfileScreen> createState() =>
      _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _incomeController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _bplStatus;
  String? _educationLevel;
  String? _employmentStatus;
  String? _farmerStatus;

  bool _disability = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final List<String> _bplOptions = [
    'Yes',
    'No',
    'Unknown',
  ];

  final List<String> _educationOptions = [
    'No formal education',
    'Primary',
    'Below 10th',
    '10th',
    '12th',
    'Diploma',
    'ITI',
    'Graduate',
    'Postgraduate',
    'PhD',
  ];

  final List<String> _employmentOptions = [
    'Employed',
    'Unemployed',
    'Student',
    'Self-employed',
    'Farmer',
    'Unorganised worker',
  ];

  final List<String> _farmerOptions = [
    'Yes',
    'No',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result =
          await ApiService.get('/api/v1/citizen/profile/');

      if (!mounted) return;

      _dobController.text =
          (result['date_of_birth'] ?? '').toString().split('T').first;
      _genderController.text = (result['gender'] ?? '').toString();
      _stateController.text = (result['state'] ?? '').toString();
      _districtController.text = (result['district'] ?? '').toString();
      _incomeController.text =
          result['annual_income']?.toString() ?? '';
      _categoryController.text = (result['category'] ?? '').toString();
      _disability = result['disability'] == true;

      // Treat Unknown or empty values as unanswered.
      _bplStatus = _readChoice(
        result['bpl_status'],
        _bplOptions,
        unknownMeansEmpty: true,
      );
      _educationLevel = _readChoice(
        result['education_level'],
        _educationOptions,
      );
      _employmentStatus = _readChoice(
        result['employment_status'],
        _employmentOptions,
      );
      _farmerStatus = _readChoice(
        result['farmer_status'],
        _farmerOptions,
        unknownMeansEmpty: true,
      );

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String? _readChoice(
    dynamic value,
    List<String> options, {
    bool unknownMeansEmpty = false,
  }) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    if (unknownMeansEmpty && text.toLowerCase() == 'unknown') {
      return null;
    }

    for (final option in options) {
      if (option.toLowerCase() == text.toLowerCase()) {
        return option;
      }
    }

    return null;
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    DateTime initialDate = DateTime(now.year - 20, now.month, now.day);

    if (_dobController.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_dobController.text);
      if (parsed != null) {
        initialDate = parsed.isAfter(now) ? now : parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
    );

    if (picked != null && mounted) {
      setState(() {
        _dobController.text =
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final dob = _dobController.text.trim();
      final income = _incomeController.text.trim();

      await ApiService.put(
        '/api/v1/citizen/profile/',
        {
          'date_of_birth':
              dob.isEmpty ? null : '${dob}T00:00:00',
          'gender': _nullableText(_genderController.text),
          'state': _nullableText(_stateController.text),
          'district': _nullableText(_districtController.text),
          'annual_income':
              income.isEmpty ? null : int.parse(income),
          'category': _nullableText(_categoryController.text),
          'disability': _disability,
          'bpl_status': _bplStatus,
          'education_level': _educationLevel,
          'employment_status': _employmentStatus,
          'farmer_status': _farmerStatus,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _nullableText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: label == 'Annual income (₹)'
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }

                final amount = int.tryParse(value.trim());

                if (amount == null || amount < 0) {
                  return 'Enter a valid non-negative whole number';
                }

                return null;
              }
            : null,
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged, {
    String hint = 'Select an option',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        hint: Text(hint),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Not sure / Not provided'),
          ),
          ...options.map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    _dobController.dispose();
    _genderController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _incomeController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      child: Icon(
                        Icons.person_outline,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your personal details',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Keep your details updated to help find '
                      'government schemes that may match your situation.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Personal information
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _chooseDate,
                      decoration: InputDecoration(
                        labelText: 'Date of birth',
                        suffixIcon: const Icon(
                          Icons.calendar_month_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _field(
                      'Gender',
                      _genderController,
                      hint: 'e.g. Female, Male, Other',
                    ),
                    _field('State', _stateController),
                    _field('District', _districtController),
                    _field(
                      'Annual income (₹)',
                      _incomeController,
                      keyboardType: TextInputType.number,
                      hint: 'Enter annual income in rupees',
                    ),
                    _field(
                      'Category',
                      _categoryController,
                      hint: 'e.g. General, OBC, SC, ST',
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Person with disability'),
                      subtitle: const Text(
                        'Select if this applies to you.',
                      ),
                      value: _disability,
                      onChanged: (value) {
                        setState(() => _disability = value);
                      },
                    ),

                    const SizedBox(height: 20),

                    // Additional eligibility information
                    Text(
                      'Scheme Eligibility Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These details help identify schemes you may '
                      'qualify for. Select "Not sure / Not provided" '
                      'when you do not know an answer.',
                    ),
                    const SizedBox(height: 16),

                    _dropdown(
                      'BPL (Below Poverty Line) Status',
                      _bplStatus,
                      _bplOptions,
                      (value) {
                        setState(() => _bplStatus = value);
                      },
                    ),

                    _dropdown(
                      'Highest Education Level',
                      _educationLevel,
                      _educationOptions,
                      (value) {
                        setState(() => _educationLevel = value);
                      },
                    ),

                    _dropdown(
                      'Employment Status',
                      _employmentStatus,
                      _employmentOptions,
                      (value) {
                        setState(() => _employmentStatus = value);
                      },
                    ),

                    _dropdown(
                      'Are you a farmer?',
                      _farmerStatus,
                      _farmerOptions,
                      (value) {
                        setState(() => _farmerStatus = value);
                      },
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Saving...' : 'Save Profile',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
