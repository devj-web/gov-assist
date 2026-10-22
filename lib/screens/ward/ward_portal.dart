import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';

class WardPortal extends StatefulWidget {
  const WardPortal({super.key});

  @override
  State<WardPortal> createState() => _WardPortalState();
}

class _WardPortalState extends State<WardPortal> {
  int tab = 0;
  String query = '';
  bool loading = false;
  String? error;

  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> citizens = [];
  List<Map<String, dynamic>> cases = [];
  List<Map<String, dynamic>> schemes = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) return value.map(_map).toList();

    if (value is Map) {
      for (final key in ['items', 'citizens', 'cases', 'schemes', 'results']) {
        if (value[key] is List) {
          return (value[key] as List).map(_map).toList();
        }
      }
    }

    return [];
  }

  String _value(
    Map<String, dynamic> item,
    List<String> keys, [
    String fallback = '—',
  ]) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  int _number(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is num) return value.toInt();
      if (value != null) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  String _citizenName(Map<String, dynamic> item) =>
      _value(item, ['citizen_name', 'name', 'full_name'], 'Citizen');

  String _schemeName(Map<String, dynamic> item) =>
      _value(item, ['scheme_name', 'name'], 'Assistance request');

  String _caseStatus(Map<String, dynamic> item) =>
      _value(item, ['status'], 'Open');

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not scheduled';
    }

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _followUp(Map<String, dynamic> item) =>
      _date(item['follow_up_at']);

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/ward/me'),
        ApiService.get('/api/v1/ward/citizens'),
        ApiService.get('/api/v1/ward/cases'),
        ApiService.get('/api/v1/schemes/'),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = _map(results[0]);
        citizens = _list(results[1]);
        cases = _list(results[2]);
        schemes = _list(results[3]);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  bool _isUpcoming(Map<String, dynamic> item) {
    final value = item['follow_up_at'];
    if (value == null) return false;

    final date = DateTime.tryParse(value.toString());
    if (date == null) return false;

    final today = DateTime.now();
    return !date.isBefore(DateTime(today.year, today.month, today.day));
  }

  Future<void> _updateCase(Map<String, dynamic> item) async {
    final id = item['case_id'] ?? item['id'];

    if (id == null) {
      _message('Case ID is missing.');
      return;
    }

    final notes = TextEditingController(
      text: item['notes']?.toString() ?? '',
    );
    final documents = TextEditingController(
      text: item['missing_documents']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: item['follow_up_at']?.toString().substring(
            0,
            item['follow_up_at'].toString().length >= 10
                ? 10
                : item['follow_up_at'].toString().length,
          ) ??
          '',
    );

    const allowedStatuses = [
      'Open',
      'In Progress',
      'Pending',
      'Resolved',
      'Closed',
    ];

    String status = _caseStatus(item);
    if (!allowedStatuses.contains(status)) status = 'Open';

    final formKey = GlobalKey<FormState>();

    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Update case #$id'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Case status',
                        border: OutlineInputBorder(),
                      ),
                      items: allowedStatuses
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => status = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: documents,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Missing documents',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Follow-up date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return DateTime.tryParse(v.trim()) == null
                            ? 'Enter a valid date'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final date = dateController.text.trim();

                Navigator.pop(ctx, {
                  'status': status,
                  'missing_documents': documents.text.trim(),
                  'notes': notes.text.trim(),
                  'follow_up_at':
                      date.isEmpty ? null : '${date}T10:00:00',
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    notes.dispose();
    documents.dispose();
    dateController.dispose();

    if (values == null) return;

    try {
      await ApiService.patch(
        '/api/v1/ward/cases/$id',
        body: values,
      );
      _message('Case updated.');
      await _loadAll();
    } catch (e) {
      _message('Update failed: $e');
    }
  }

  Future<void> _createCase() async {
    if (citizens.isEmpty) {
      _message('No consented citizens available.');
      return;
    }

    final selectedCitizen = ValueNotifier<int?>(
      _number(citizens.first, ['citizen_id', 'user_id', 'id']),
    );
    final selectedScheme = ValueNotifier<int?>(null);

    final documents = TextEditingController();
    final notes = TextEditingController();
    final dateController = TextEditingController();

    String status = 'Open';
    final formKey = GlobalKey<FormState>();

    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create assistance case'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<int?>(
                      valueListenable: selectedCitizen,
                      builder: (_, selected, __) {
                        return DropdownButtonFormField<int>(
                          initialValue: selected,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Consented citizen',
                            border: OutlineInputBorder(),
                          ),
                          items: citizens.map((c) {
                            final citizenId = _number(
                              c,
                              ['citizen_id', 'user_id', 'id'],
                            );
                            return DropdownMenuItem(
                              value: citizenId,
                              child: Text(
                                '${_citizenName(c)} (#$citizenId)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => selectedCitizen.value = v,
                          validator: (v) =>
                              v == null ? 'Select a citizen' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<int?>(
                      valueListenable: selectedScheme,
                      builder: (_, selected, __) {
                        return DropdownButtonFormField<int?>(
                          initialValue: selected,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Scheme (optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('No scheme selected'),
                            ),
                            ...schemes.map((s) {
                              final schemeId = _number(s, ['id', 'scheme_id']);
                              return DropdownMenuItem<int?>(
                                value: schemeId == 0 ? null : schemeId,
                                child: Text(
                                  _schemeName(s),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (v) => selectedScheme.value = v,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Open', child: Text('Open')),
                        DropdownMenuItem(
                          value: 'In Progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => status = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: documents,
                      decoration: const InputDecoration(
                        labelText: 'Missing documents',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Follow-up date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return DateTime.tryParse(v.trim()) == null
                            ? 'Enter a valid date'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final citizenId = selectedCitizen.value;
                if (citizenId == null) return;

                final date = dateController.text.trim();

                Navigator.pop(ctx, {
                  'citizen_id': citizenId,
                  'scheme_id': selectedScheme.value,
                  'status': status,
                  'missing_documents': documents.text.trim(),
                  'notes': notes.text.trim(),
                  'follow_up_at':
                      date.isEmpty ? null : '${date}T10:00:00',
                });
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    selectedCitizen.dispose();
    selectedScheme.dispose();
    documents.dispose();
    notes.dispose();
    dateController.dispose();

    if (values == null) return;

    try {
      await ApiService.post('/api/v1/ward/cases', values);
      _message('Assistance case created.');
      await _loadAll();
    } catch (e) {
      _message('Creation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Overview',
      'Citizens',
      'Assistance cases',
      'Follow-ups',
    ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: const Text(
          'Ward Member Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Home',
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      titles.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(titles[i]),
                          selected: tab == i,
                          onSelected: (_) => setState(() => tab = i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (loading) const LinearProgressIndicator(minHeight: 2),
              if (error != null)
                MaterialBanner(
                  content: Text(error!),
                  leading: const Icon(Icons.error_outline),
                  actions: [
                    TextButton(
                      onPressed: _loadAll,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: IndexedStack(
                  index: tab,
                  children: [
                    _overview(),
                    _citizens(),
                    _cases(),
                    _followups(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _overview() {
  final assignment = _map(dashboard['assignment']);

  final wardParts = [
    _value(assignment, ['ward_name'], ''),
    _value(assignment, ['local_body'], ''),
    _value(assignment, ['district'], ''),
    _value(assignment, ['state'], ''),
  ].where((s) => s.isNotEmpty).toList();

  final ward = wardParts.isEmpty
      ? 'Not assigned'
      : wardParts.join(' • ');

  final openCases = cases.where((c) {
    final status = _caseStatus(c).toLowerCase();
    return status != 'resolved' && status != 'closed';
  }).length;

  final upcoming = cases.where(_isUpcoming).length;

  return ListView(
    padding: const EdgeInsets.all(22),
    children: [
      // Welcome banner
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: teal,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WARD MEMBER WORKSPACE',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Welcome, Ward Member',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage resident assistance and follow-ups for your ward.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 22),

      // Metric cards: keep them in one row
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Metric(
              title: 'Assigned ward',
              value: ward,
              icon: Icons.location_city,
              color: teal,
            ),
            _Metric(
              title: 'Consented citizens',
              value: '${citizens.length}',
              icon: Icons.groups_outlined,
              color: navy,
            ),
            _Metric(
              title: 'Open assistance cases',
              value: '$openCases',
              icon: Icons.assignment_outlined,
              color: purple,
            ),
            _Metric(
              title: 'Upcoming follow-ups',
              value: '$upcoming',
              icon: Icons.event_available_outlined,
              color: const Color(0xFFB7791F),
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Recent cases
      const Text(
        'Recent assistance cases',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      if (cases.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text('No assistance cases found.'),
          ),
        ),

      ...cases.take(3).map(_caseTile),

      const SizedBox(height: 12),

      // Privacy notice
      _notice(
        'Privacy reminder',
        'Only access or update citizen information when consent is recorded. '
            'The backend must enforce this permission.',
      ),
    ],
  );
}

  Widget _citizens() {
    final filtered = citizens.where((c) {
      final text = '${_citizenName(c)} '
          '${_value(c, ['citizen_id', 'user_id', 'id'], '')} '
          '${_value(c, ['email'], '')}';
      return text.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Consented citizens',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('Citizens who have consented to assistance.'),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search citizen name or ID',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No matching consented citizens found.'),
            ),
          ),
        ...filtered.map((citizen) {
          final id = _value(citizen, ['citizen_id', 'user_id', 'id']);
          final location = [
            _value(citizen, ['district'], ''),
            _value(citizen, ['state'], ''),
          ].where((s) => s.isNotEmpty).join(' • ');

          return Card(
            color: Colors.white,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5EEF9),
                child: Icon(Icons.person_outline, color: navy),
              ),
              title: Text(_citizenName(citizen)),
              subtitle: Text(
                'Citizen ID: $id'
                '${location.isNotEmpty ? '\n$location' : ''}'
                '\n${_value(citizen, ['email'], '')}',
              ),
              isThreeLine: true,
              trailing: const Chip(
                label: Text('Consented'),
                backgroundColor: Color(0xFFE0F4EA),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _cases() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Assistance case tracking',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: _createCase,
              icon: const Icon(Icons.add),
              label: const Text('New case'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Review status, missing documents and follow-up dates.'),
        const SizedBox(height: 14),
        if (cases.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No assistance cases found.'),
            ),
          ),
        ...cases.map(_caseTile),
      ],
    );
  }

  Widget _followups() {
    final upcoming = cases.where(_isUpcoming).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse('${a['follow_up_at']}');
        final db = DateTime.tryParse('${b['follow_up_at']}');
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Upcoming follow-ups',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text('Prioritize the next action for each assistance request.'),
        const SizedBox(height: 14),
        if (upcoming.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No upcoming follow-ups are scheduled.'),
            ),
          ),
        ...upcoming.map((c) {
          return Card(
            color: Colors.white,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5F4F1),
                child: Icon(Icons.calendar_month, color: teal),
              ),
              title: Text(_schemeName(c)),
              subtitle: Text(
                'Citizen ID: ${_value(c, ['citizen_id'])}\n'
                'Status: ${_caseStatus(c)}',
              ),
              isThreeLine: true,
              trailing: Text(
                _followUp(c),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onTap: () => _updateCase(c),
            ),
          );
        }),
      ],
    );
  }

  Widget _caseTile(Map<String, dynamic> item) {
    final status = _caseStatus(item);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _updateCase(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _schemeName(item),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Citizen: ${_value(item, ['citizen_name'], 'Citizen')}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 5),
              Text(
                'Missing documents: '
                '${_value(item, ['missing_documents'], 'None recorded')}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 16, color: muted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Follow-up: ${_followUp(item)}',
                      style: const TextStyle(color: muted),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 17, color: navy),
                  const SizedBox(width: 4),
                  const Text('Edit', style: TextStyle(color: navy)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();

    final color = normalized == 'resolved' || normalized == 'closed'
        ? const Color(0xFFE0F4EA)
        : normalized == 'in progress'
            ? const Color(0xFFE0EAFE)
            : const Color(0xFFFFF1D6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _notice(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(body, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

 @override
Widget build(BuildContext context) => SizedBox(
  width: 250,
  child: Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}