
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';

class AdminPortal extends StatefulWidget {
  const AdminPortal({super.key});

  @override
  State<AdminPortal> createState() => _AdminPortalState();
}

class _AdminPortalState extends State<AdminPortal> {
  int tab = 0;

  bool loadingMembers = false;
  bool loadingSchemes = false;

  String? memberError;
  String? schemeError;

  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> schemes = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadSchemes();
  }

  Future<void> _loadMembers() async {
    if (ApiService.token == null) {
      setState(() {
        memberError = 'Please sign in as an admin first.';
      });
      return;
    }

    setState(() {
      loadingMembers = true;
      memberError = null;
    });

    try {
      final result =
          await ApiService.get('/api/v1/admin/ward-members');

      if (result is List) {
        members = result
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        throw Exception('Unexpected ward accounts response.');
      }
    } catch (e) {
      memberError = _cleanError(e);
    } finally {
      if (mounted) {
        setState(() => loadingMembers = false);
      }
    }
  }

  Future<void> _loadSchemes() async {
    if (ApiService.token == null) {
      setState(() {
        schemeError = 'Please sign in as an admin first.';
      });
      return;
    }

    setState(() {
      loadingSchemes = true;
      schemeError = null;
    });

    try {
      final result = await ApiService.get('/api/v1/schemes/');

      dynamic items = result;
      if (result is Map && result['items'] is List) {
        items = result['items'];
      } else if (result is Map && result['schemes'] is List) {
        items = result['schemes'];
      }

      if (items is List) {
        schemes = items
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        throw Exception('Unexpected scheme catalogue response.');
      }
    } catch (e) {
      schemeError = _cleanError(e);
    } finally {
      if (mounted) {
        setState(() => loadingSchemes = false);
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _createAccount() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final state = TextEditingController(text: 'Kerala');
    final district = TextEditingController(text: 'Alappuzha');
    final localBody = TextEditingController(
      text: 'Mavelikara Municipality',
    );
    final ward = TextEditingController(text: 'Ward 1');
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create ward member account'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(name, 'Full name'),
                    _field(email, 'Email address'),
                    _field(
                      password,
                      'Temporary password (8+ characters)',
                      obscure: true,
                    ),
                    _field(state, 'State'),
                    _field(district, 'District'),
                    _field(localBody, 'Local body'),
                    _field(ward, 'Ward name or number'),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => saving = true);

                      try {
                        await ApiService.post(
                          '/api/v1/admin/ward-members',
                          {
                            'name': name.text.trim(),
                            'email': email.text.trim(),
                            'password': password.text,
                            'state': state.text.trim(),
                            'district': district.text.trim(),
                            'local_body': localBody.text.trim(),
                            'ward_name': ward.text.trim(),
                          },
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _message('Ward member account created.');
                        await _loadMembers();
                      } catch (e) {
                        setDialogState(() => saving = false);
                        _message(_cleanError(e));
                      }
                    },
              child: Text(saving ? 'Creating...' : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }
          if (obscure && value.length < 8) {
            return 'Use at least 8 characters';
          }
          if (label == 'Email address' &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
            return 'Enter a valid email address';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _assignWard(Map<String, dynamic> member) async {
    final assignment =
        Map<String, dynamic>.from(member['assignment'] ?? {});

    final state = TextEditingController(
      text: '${assignment['state'] ?? 'Kerala'}',
    );
    final district = TextEditingController(
      text: '${assignment['district'] ?? ''}',
    );
    final localBody = TextEditingController(
      text: '${assignment['local_body'] ?? ''}',
    );
    final ward = TextEditingController(
      text: '${assignment['ward_name'] ?? ''}',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Assign ward to ${member['name'] ?? 'member'}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(state, 'State'),
                _field(district, 'District'),
                _field(localBody, 'Local body'),
                _field(ward, 'Ward name or number'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final id = member['user_id'];
              if (id == null) {
                _message('Ward member ID is missing.');
                return;
              }

              try {
                await ApiService.put(
                  '/api/v1/admin/ward-members/$id/assignment',
                  {
                    'state': state.text.trim(),
                    'district': district.text.trim(),
                    'local_body': localBody.text.trim(),
                    'ward_name': ward.text.trim(),
                  },
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _message('Ward assignment updated.');
                await _loadMembers();
              } catch (e) {
                _message(_cleanError(e));
              }
            },
            child: const Text('Save assignment'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMember(Map<String, dynamic> member) async {
    final id = member['user_id'];
    if (id == null) return;

    final currentlyActive = member['is_active'] == true;

    try {
      await ApiService.patch(
        '/api/v1/admin/ward-members/$id/active',
        query: {'active': (!currentlyActive).toString()},
      );
      _message(
        currentlyActive
            ? 'Ward member disabled.'
            : 'Ward member enabled.',
      );
      await _loadMembers();
    } catch (e) {
      _message(_cleanError(e));
    }
  }

  Future<void> _createScheme() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final category = TextEditingController();
    final state = TextEditingController(text: 'Kerala');
    final description = TextEditingController();
    final url = TextEditingController();
    String type = 'Central';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add scheme'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(name, 'Scheme name'),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Scheme type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Central',
                          child: Text('Central'),
                        ),
                        DropdownMenuItem(
                          value: 'State',
                          child: Text('State'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => type = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _field(category, 'Category'),
                    _field(state, 'State (e.g. Kerala or All India)'),
                    TextFormField(
                      controller: description,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Description is required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    _field(url, 'Official URL (optional)'),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  await ApiService.post(
                    '/api/v1/admin/schemes',
                    {
                      'name': name.text.trim(),
                      'scheme_type': type,
                      'category': category.text.trim(),
                      'state': state.text.trim().isEmpty
                          ? null
                          : state.text.trim(),
                      'description': description.text.trim(),
                      'official_url': url.text.trim().isEmpty
                          ? null
                          : url.text.trim(),
                    },
                  );

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _message('Scheme created.');
                  await _loadSchemes();
                } catch (e) {
                  _message(_cleanError(e));
                }
              },
              child: const Text('Save scheme'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleScheme(Map<String, dynamic> scheme) async {
    final id = scheme['id'] ?? scheme['scheme_id'];
    if (id == null) {
      _message('Scheme ID is missing; cannot change its status.');
      return;
    }

    final active = scheme['is_active'] == true;

    try {
      await ApiService.patch(
        '/api/v1/admin/schemes/$id/active',
        query: {'active': (!active).toString()},
      );
      _message(active ? 'Scheme deactivated.' : 'Scheme activated.');
      await _loadSchemes();
    } catch (e) {
      _message(_cleanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Overview',
      'Ward accounts',
      'Scheme catalogue',
      'Reports',
    ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: const Text(
          'GovAssist AI • Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh data',
            onPressed: () {
              _loadMembers();
              _loadSchemes();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Return home',
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
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
                      labels.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(labels[i]),
                          selected: tab == i,
                          onSelected: (_) => setState(() => tab = i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: tab,
                  children: [
                    _overview(),
                    _accounts(),
                    _schemes(),
                    _reports(),
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
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: purple,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADMINISTRATION',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Manage GovAssist AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage ward accounts and maintain the scheme catalogue.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(
              'Ward members',
              loadingMembers ? '…' : '${members.length}',
              Icons.groups_outlined,
            ),
            _Metric(
              'Schemes in catalogue',
              loadingSchemes ? '…' : '${schemes.length}',
              Icons.account_balance_outlined,
            ),
            _Metric(
              'Active ward accounts',
              '${members.where((m) => m['is_active'] == true).length}',
              Icons.verified_user_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (memberError != null) _errorPanel(memberError!, _loadMembers),
        if (schemeError != null) _errorPanel(schemeError!, _loadSchemes),
        FilledButton.icon(
          onPressed: () => setState(() => tab = 1),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Manage ward accounts'),
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => setState(() => tab = 2),
          icon: const Icon(Icons.account_balance_outlined),
          label: const Text('Manage scheme catalogue'),
        ),
      ],
    );
  }

  Widget _accounts() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ward member accounts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: _createAccount,
              icon: const Icon(Icons.add),
              label: const Text('Create account'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Live accounts and ward assignments from the backend.'),
        const SizedBox(height: 14),
        if (loadingMembers)
          const Center(child: CircularProgressIndicator()),
        if (memberError != null) _errorPanel(memberError!, _loadMembers),
        if (!loadingMembers &&
            memberError == null &&
            members.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No ward member accounts found.'),
            ),
          ),
        ...members.map((member) {
          final assignment =
              Map<String, dynamic>.from(member['assignment'] ?? {});
          final active = member['is_active'] == true;
          final ward = assignment['ward_name'] ?? 'Ward not assigned';
          final district = assignment['district'] ?? 'District not set';
          final state = assignment['state'] ?? '';

          return Card(
            color: Colors.white,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEDE7F6),
                child: Icon(Icons.person_outline, color: purple),
              ),
              title: Text('${member['name'] ?? 'Ward Member'}'),
              subtitle: Text(
                '${member['email'] ?? ''}\n'
                '$ward • $district'
                '${state.toString().isNotEmpty ? ' • $state' : ''}\n'
                '${active ? 'Active' : 'Disabled'}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'assign') _assignWard(member);
                  if (value == 'toggle') _toggleMember(member);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'assign',
                    child: Text('Edit ward assignment'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(active ? 'Disable account' : 'Enable account'),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _schemes() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Scheme catalogue',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: _createScheme,
              icon: const Icon(Icons.add),
              label: const Text('Add scheme'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Schemes loaded from the API. Verify official criteria before use.',
        ),
        const SizedBox(height: 14),
        if (loadingSchemes)
          const Center(child: CircularProgressIndicator()),
        if (schemeError != null) _errorPanel(schemeError!, _loadSchemes),
        if (!loadingSchemes && schemeError == null && schemes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No schemes were returned by the catalogue API.'),
            ),
          ),
        ...schemes.map((scheme) {
          final active = scheme['is_active'] == true;
          final name =
              scheme['name'] ?? scheme['schemeName'] ?? 'Unnamed scheme';
          final category = scheme['category'] ?? 'Uncategorised';
          final type =
              scheme['scheme_type'] ?? scheme['schemeType'] ?? 'Type not set';
          final state = scheme['state'] ?? 'All states';

          return Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_outlined,
                color: navy,
              ),
              title: Text('$name'),
              subtitle: Text('$category • $type\n$state'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'toggle') _toggleScheme(scheme);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(active ? 'Deactivate' : 'Activate'),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _reports() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: const [
        Text(
          'Aggregate reports',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Live aggregate reporting is not available yet. '
              'The current backend does not provide an admin reports '
              'endpoint, so this page does not display fabricated counts.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorPanel(String error, Future<void> Function() retry) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => retry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Metric(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: purple, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
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
}
