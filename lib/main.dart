import 'package:flutter/material.dart';
import 'screens/ward/ward_portal.dart';
import 'screens/admin/admin_portal.dart';
import 'core/api_service.dart';
import 'models/scheme.dart';
import 'screens/citizen/citizen_profile_screen.dart';
void main() {
  runApp(const GovAssistApp());
}

const navy = Color(0xFF123B70);
const pageBg = Color(0xFFF5F7FB);
const muted = Color(0xFF64748B);

class GovAssistApp extends StatelessWidget {
  const GovAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GovAssist AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        scaffoldBackgroundColor: pageBg,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: navy,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GovAssist AI',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                            Text(
                              'Government benefits, made accessible',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'YOUR BENEFITS. YOUR OPPORTUNITIES.',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Discover government benefits you may be eligible for.',
                    style: TextStyle(
                      fontSize: 40,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Explore central and state schemes, scholarships, '
                    'pensions, subsidies and welfare programmes in one place.',
                    style: TextStyle(color: muted, fontSize: 16, height: 1.7),
                  ),
                  const SizedBox(height: 30),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FeatureChip(Icons.search, 'Find schemes'),
                      FeatureChip(Icons.fact_check, 'Explore eligibility'),
                      FeatureChip(Icons.support_agent, 'Local assistance'),
                    ],
                  ),
                  const SizedBox(height: 38),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final items = [
                        PortalCard(
                          icon: Icons.person_outline,
                          title: 'Citizen Portal',
                          description:
                              'Discover schemes and explore potential '
                              'benefits.',
                          buttonText: 'Continue as citizen',
                          color: navy,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(role: 'CITIZEN'),
                            ),
                          ),
                        ),
                        PortalCard(
                          icon: Icons.groups_outlined,
                          title: 'Ward Member Portal',
                          description:
                              'Help residents and track assistance requests.',
                          buttonText: 'Ward member sign in',
                          color: const Color(0xFF087E72),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(role: 'WARD_MEMBER'),
                            ),
                          ),
                        ),
                        PortalCard(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Admin Portal',
                          description:
                              'Manage schemes and authorized ward accounts.',
                          buttonText: 'Admin sign in',
                          color: const Color(0xFF6741A5),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(role: 'ADMIN'),
                            ),
                          ),
                        ),
                      ];

                      if (constraints.maxWidth >= 720) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items
                              .map(
                                (item) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: item,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Column(
                        children: items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: item,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'Explore public services in one place.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const FeatureChip(this.icon, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: navy, size: 18),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE1E7F0)),
    );
  }
}

class PortalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final Color color;
  final VoidCallback onTap;

  const PortalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 34, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: muted, height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.all(14),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

void showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This portal will be implemented in the next phase.'),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, this.role = 'CITIZEN'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool obscure = true;
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter email and password'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result = await ApiService.login(
        email.text.trim(),
        password.text,
      );

      String actualRole =
          (result['role'] ?? '').toString().toUpperCase();

      if (actualRole.isEmpty) {
        final me = await ApiService.get('/api/v1/auth/me');
        if (me is Map) {
          actualRole = (me['role'] ?? '').toString().toUpperCase();
        }
      }

      if (actualRole != widget.role) {
        ApiService.token = null;
        throw Exception(
          'This account does not have ${widget.role} access.',
        );
      }

      if (!mounted) return;

      late final Widget destination;

      if (actualRole == 'ADMIN') {
        destination = const AdminPortal();
      } else if (actualRole == 'WARD_MEMBER') {
        destination = const WardPortal();
      } else if (actualRole == 'CITIZEN') {
        destination = const CitizenDashboard();
      } else {
        throw Exception(
          'This account role is not supported in the app.',
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.role) {
      'ADMIN' => 'Admin sign in',
      'WARD_MEMBER' => 'Ward Member sign in',
      _ => 'Citizen sign in',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('GovAssist AI'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 55,
                      color: navy,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: password,
                      obscureText: obscure,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => obscure = !obscure);
                          },
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    FilledButton(
                      onPressed: loading ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        padding: const EdgeInsets.all(15),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),

                    // Registration link for citizens only.
                    if (widget.role == 'CITIZEN') ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'New citizen? Create an account',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await ApiService.post(
        '/api/v1/auth/register',
        {
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please sign in.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1,
                        size: 54,
                        color: navy,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Join GovAssist AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a citizen account to explore '
                        'government schemes and benefits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted),
                      ),
                      const SizedBox(height: 25),

                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().length < 2) {
                            return 'Enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: 'Use at least 8 characters',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirm =
                                    !_obscureConfirm;
                              });
                            },
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: _loading ? null : _register,
                        style: FilledButton.styleFrom(
                          backgroundColor: navy,
                          padding: const EdgeInsets.all(15),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Already registered? Sign in',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  List<Scheme> schemes = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ApiService.get('/api/v1/schemes/');
      if (response is! List) {
        throw Exception('Unexpected scheme data received from server.');
      }
      final loaded = response
          .whereType<Map>()
          .map((item) => Scheme.fromJson(Map<String, dynamic>.from(item)))
          .where((scheme) => scheme.isActive)
          .toList();
      if (!mounted) return;
      setState(() {
        schemes = loaded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('GovAssist AI',
            style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExploreSchemesScreen()),
            ),
            icon: const Icon(Icons.search, color: navy),
            tooltip: 'Explore schemes',
          ),
          IconButton(
            onPressed: _loadSchemes,
            icon: const Icon(Icons.refresh, color: navy),
            tooltip: 'Refresh schemes',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CITIZEN DASHBOARD',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 14),
                    Text('Welcome to GovAssist AI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text(
                      'Explore schemes, scholarships, pensions and government benefits that may be relevant to you.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text('Explore government schemes',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Could not load schemes: $error'),
                        const SizedBox(height: 10),
                        FilledButton(
                            onPressed: _loadSchemes,
                            child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              else if (schemes.isEmpty)
                const Text('No active schemes are available right now.')
              else
                ...schemes.take(3).map((scheme) => SchemeCard(scheme: scheme)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExploreSchemesScreen()),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Explore all schemes'),
                style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scheme information should be verified with the official programme before applying.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CitizenNavigation(selectedIndex: 0),
    );
  }
}

class SchemeCard extends StatelessWidget {
  final Scheme scheme;

  const SchemeCard({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE1E7F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3ECFA),
          child: Icon(scheme.icon, color: navy),
        ),
        title: Text(scheme.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('${scheme.category} • ${scheme.level}'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchemeDetailsScreen(scheme: scheme),
          ),
        ),
      ),
    );
  }
}

class CitizenNavigation extends StatelessWidget {
  final int selectedIndex;

  const CitizenNavigation({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onDestinationSelected: (index) {
        if (index == 0 && selectedIndex != 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CitizenDashboard()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const ExploreSchemesScreen()),
          );
        } 
        else if (index == 2) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CitizenProfileScreen(),
    ),
  );}

      },
    );
  }
}

class ExploreSchemesScreen extends StatefulWidget {
  const ExploreSchemesScreen({super.key});

  @override
  State<ExploreSchemesScreen> createState() => _ExploreSchemesScreenState();
}

class _ExploreSchemesScreenState extends State<ExploreSchemesScreen> {
  String query = '';
  String category = 'All';
  String level = 'All';
  List<Scheme> schemes = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ApiService.get('/api/v1/schemes/');
      if (response is! List) {
        throw Exception('Unexpected scheme data received from server.');
      }
      final loaded = response
          .whereType<Map>()
          .map((item) => Scheme.fromJson(Map<String, dynamic>.from(item)))
          .where((scheme) => scheme.isActive)
          .toList();
      if (!mounted) return;
      setState(() {
        schemes = loaded;
        loading = false;
        if (category != 'All' &&
            !loaded.any((scheme) => scheme.category == category)) {
          category = 'All';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  List<String> get categories => [
        'All',
        ...schemes.map((scheme) => scheme.category).toSet().toList()..sort(),
      ];

  List<Scheme> get results {
    final search = query.toLowerCase().trim();
    return schemes.where((scheme) {
      final matchesSearch = search.isEmpty ||
          scheme.name.toLowerCase().contains(search) ||
          scheme.category.toLowerCase().contains(search) ||
          scheme.description.toLowerCase().contains(search) ||
          scheme.state.toLowerCase().contains(search);
      final matchesLevel = level == 'All' ||
          scheme.level.toLowerCase() == level.toLowerCase() ||
          (level == 'State' && scheme.level.toLowerCase().contains('state')) ||
          (level == 'Central' &&
              scheme.level.toLowerCase().contains('central'));
      return matchesSearch &&
          (category == 'All' || category == scheme.category) &&
          matchesLevel;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore schemes'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSchemes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh schemes',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Find benefits for you',
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Search and filter the active scheme catalogue.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 22),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'Search schemes or benefits',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: categories.contains(category) ? category : 'All',
                decoration: const InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(
                  labelText: 'Scheme level',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: const ['All', 'Central', 'State']
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => level = value);
                },
              ),
              const SizedBox(height: 20),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Could not load schemes: $error'),
                        const SizedBox(height: 10),
                        FilledButton(
                            onPressed: _loadSchemes,
                            child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              else ...[
                Text('${results.length} schemes found',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(child: Text('No matching schemes found.')),
                  ),
                ...results.map((scheme) => SchemeCard(scheme: scheme)),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CitizenNavigation(selectedIndex: 1),
    );
  }
}

class SchemeDetailsScreen extends StatelessWidget {
  final Scheme scheme;

  const SchemeDetailsScreen({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scheme details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(scheme.icon, color: Colors.white, size: 42),
                    const SizedBox(height: 18),
                    Text(
                      scheme.name,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('${scheme.category} • ${scheme.level}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DetailSection('About this scheme', scheme.description),
              DetailSection('State or coverage', scheme.state),
              DetailSection(
                'Eligibility information',
                'Detailed eligibility rules are not included in this scheme catalogue. '
                    'Check the current official programme requirements before applying.',
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'This is sample information, not an official eligibility '
                  'decision. Verify the current scheme rules before applying.',
                  style: TextStyle(height: 1.6),
                ),
              ),
              const SizedBox(height: 20),
         FilledButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EligibilityResultsScreen(),
      ),
    );
  },
  icon: const Icon(Icons.fact_check),
  label: const Text('Check my eligibility'),
  style: FilledButton.styleFrom(
    backgroundColor: navy,
    padding: const EdgeInsets.all(16),
  ),
),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  final String title;
  final String text;

  const DetailSection(this.title, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(height: 1.6)),
          ],
        ),
      ),
    );
  }
}class EligibilityResultsScreen extends StatefulWidget {
  const EligibilityResultsScreen({super.key});

  @override
  State<EligibilityResultsScreen> createState() =>
      _EligibilityResultsScreenState();
}

class _EligibilityResultsScreenState
    extends State<EligibilityResultsScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response =
          await ApiService.get('/api/v1/eligibility/matches');

      if (response is! Map) {
        throw Exception('Unexpected response from eligibility API.');
      }

      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(response);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  List<dynamic> listValue(String key) {
    final value = data?[key];
    return value is List ? value : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eligibility results'),
        actions: [
          IconButton(
            onPressed: loadResults,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh results',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadResults,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Your potential scheme matches',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data?['total_potential_schemes'] ?? 0} schemes evaluated',
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _eligibilityMetric(
                            'Potential matches',
                            data?['potential_matches'] ?? 0,
                            Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _eligibilityMetric(
                            'Need verification',
                            data?['schemes_needing_verification'] ?? 0,
                            Icons.fact_check_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (listValue('matches').isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('No scheme results were returned.'),
                        ),
                      ),
                    ...listValue('matches').map((item) {
                      if (item is! Map) {
                        return const SizedBox.shrink();
                      }

                      final scheme = Map<String, dynamic>.from(item);
                      final reasons = scheme['reasons'] is List
                          ? scheme['reasons'] as List
                          : [];
                      final checks = scheme['needs_verification'] is List
                          ? scheme['needs_verification'] as List
                          : [];
                      final actions = scheme['next_actions'] is List
                          ? scheme['next_actions'] as List
                          : [];
                      final officialChecks =
                          scheme['official_checks'] is List
                              ? scheme['official_checks'] as List
                              : [];

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (scheme['name'] ?? 'Unnamed scheme')
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${scheme['category'] ?? 'Other'} • '
                                '${scheme['scheme_type'] ?? 'Unknown'}',
                                style: const TextStyle(color: muted),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                (scheme['description'] ?? '').toString(),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4D8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  (scheme['match_status'] ??
                                          'needs_verification')
                                      .toString()
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (reasons.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Text(
                                  'Reasons',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                ...reasons.map(
                                  (v) => _eligibilityBullet(v.toString()),
                                ),
                              ],
                              if (checks.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Information to verify',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                ...checks.map(
                                  (v) => _eligibilityBullet(v.toString()),
                                ),
                              ],
                              if (officialChecks.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Official checks',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                ...officialChecks.map(
                                  (v) => _eligibilityBullet(v.toString()),
                                ),
                              ],
                              if (actions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Next steps',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                ...actions.map(
                                  (v) => _eligibilityBullet(v.toString()),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Text(
                      (data?['notice'] ??
                              'Verify scheme conditions with the official authority.')
                          .toString(),
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _eligibilityMetric(
      String title, dynamic value, IconData icon) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: navy, size: 28),
            const SizedBox(height: 10),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _eligibilityBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}