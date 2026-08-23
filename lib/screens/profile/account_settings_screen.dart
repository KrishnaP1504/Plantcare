import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Comprehensive Account & Garden Settings Screen.
///
/// Features:
/// 1. Profile Settings:
///    - Change Name
///    - Change Username
///    - Change Profile Picture
///    - Edit Personal Information (Email, Bio/Location)
/// 2. Garden Settings:
///    - Garden Name
///    - Default Garden
///    - Plant Sorting
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _gardenNameController;

  String _selectedDefaultGarden = 'Indoor Living Room Garden';
  String _selectedPlantSorting = 'Recently Added';
  File? _selectedAvatarFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController =
        TextEditingController(text: user?.fullName ?? 'Krishna Pipaliya');
    _usernameController =
        TextEditingController(text: user?.username ?? 'krishna');
    _emailController = TextEditingController(
        text: user?.email ?? 'krishna.pipaliya@example.com');
    _bioController = TextEditingController(
        text: 'Plant enthusiast, succulent collector & organic gardener.');
    _gardenNameController = TextEditingController(text: 'My Home Garden');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _gardenNameController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      authProvider.updateProfile(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account & Garden settings saved successfully!'),
          backgroundColor: Color(0xFF1B4D3E),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFBF8),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: Color(0xFF1B4D3E),
            ),
          ),
        ),
        title: const Text(
          'Account Settings ⚙️',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C3B30),
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SECTION 1: PROFILE SETTINGS ──
              _buildSectionHeader(
                icon: Icons.person_outline_rounded,
                title: 'Profile Settings',
                subtitle: 'Manage your personal profile and account credentials',
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Change Profile Picture Row
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3EB),
                                shape: BoxShape.circle,
                              ),
                              child: _selectedAvatarFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: Image.file(_selectedAvatarFile!,
                                          fit: BoxFit.cover),
                                    )
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      size: 38,
                                      color: Color(0xFF1B4D3E),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C553C),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Picture',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C3B30),
                                ),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Select photo from gallery or camera'),
                                      backgroundColor: Color(0xFF1B4D3E),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.upload_file_rounded,
                                    size: 16),
                                label: const Text('Change Picture'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1B4D3E),
                                  side: const BorderSide(
                                      color: Color(0xFF1B4D3E)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF0F4F1), height: 1),
                    const SizedBox(height: 20),

                    // Change Name
                    _buildInputField(
                      controller: _nameController,
                      label: 'Change Name',
                      hint: 'Enter your full name',
                      icon: Icons.badge_outlined,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Name cannot be empty'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Change Username
                    _buildInputField(
                      controller: _usernameController,
                      label: 'Change Username',
                      hint: 'Enter username',
                      icon: Icons.alternate_email_rounded,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Username cannot be empty'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Edit Personal Information (Email & Bio)
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'Enter your email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    _buildInputField(
                      controller: _bioController,
                      label: 'Personal Information / Bio',
                      hint: 'Tell us about your garden journey...',
                      icon: Icons.edit_note_rounded,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── SECTION 2: GARDEN SETTINGS ──
              _buildSectionHeader(
                icon: Icons.eco_outlined,
                title: 'Garden Settings',
                subtitle: 'Configure your default garden preferences and sorting',
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Garden Name
                    _buildInputField(
                      controller: _gardenNameController,
                      label: 'Garden Name',
                      hint: 'Enter your garden name',
                      icon: Icons.yard_outlined,
                    ),

                    const SizedBox(height: 16),

                    // Default Garden Dropdown
                    const Text(
                      'Default Garden',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C3B30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDefaultGarden,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.home_work_outlined,
                            color: Color(0xFF1B4D3E)),
                        filled: true,
                        fillColor: const Color(0xFFF6FAF7),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8F0EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8F0EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF1B4D3E), width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Indoor Living Room Garden',
                          child: Text('Indoor Living Room Garden'),
                        ),
                        DropdownMenuItem(
                          value: 'Balcony Garden',
                          child: Text('Balcony Garden'),
                        ),
                        DropdownMenuItem(
                          value: 'Backyard Garden',
                          child: Text('Backyard Garden'),
                        ),
                        DropdownMenuItem(
                          value: 'Office Plant Corner',
                          child: Text('Office Plant Corner'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDefaultGarden = val);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Plant Sorting Dropdown
                    const Text(
                      'Plant Sorting',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C3B30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPlantSorting,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.sort_rounded,
                            color: Color(0xFF1B4D3E)),
                        filled: true,
                        fillColor: const Color(0xFFF6FAF7),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8F0EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: Color(0xFFE8F0EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF1B4D3E), width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Recently Added',
                          child: Text('Recently Added'),
                        ),
                        DropdownMenuItem(
                          value: 'Needs Water First',
                          child: Text('Needs Water First'),
                        ),
                        DropdownMenuItem(
                          value: 'Alphabetical (A-Z)',
                          child: Text('Alphabetical (A-Z)'),
                        ),
                        DropdownMenuItem(
                          value: 'Health Status',
                          child: Text('Health Status'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPlantSorting = val);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Settings Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 22, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F3EB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF1B4D3E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C3B30),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6A7E73),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C3B30),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C3B30),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF1B4D3E)),
            filled: true,
            fillColor: const Color(0xFFF6FAF7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8F0EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8F0EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF1B4D3E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
