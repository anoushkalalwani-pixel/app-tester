import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // for Cupertino Icons
import 'package:draft_1/homepage.dart'; // assuming homepage is imported
import 'package:draft_1/pages/sync_settings.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:draft_1/theme/theme_controller.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  _UserProfileFormState createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.pencil, color: colors.onSurface),
            onPressed: () {
              // Handle edit logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTextField('First Name', _firstNameController),
              const VGap(AppSpacing.lg),
              _buildTextField('Last Name', _lastNameController),
              const VGap(AppSpacing.lg),
              _buildTextField('Grade', _gradeController, isNumeric: true),
              const VGap(AppSpacing.lg),
              _buildTextField('Email', _emailController, isEmail: true),
              const VGap(AppSpacing.lg),
              _buildThemeToggle(colors),
              const VGap(AppSpacing.lg),
              _buildCloudSyncTile(colors),
              const VGap(AppSpacing.xxl),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => HomePage()));
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudSyncTile(AppColors colors) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.md,
      child: ListTile(
        leading: Icon(Icons.cloud_sync, color: colors.onSurface),
        title: Text(
          'Cloud sync',
          style: context.text.titleMedium?.copyWith(
            color: colors.onSurface,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Back up and restore your study data',
          style: context.text.bodyLarge?.copyWith(color: colors.onSurface),
        ),
        trailing: Icon(CupertinoIcons.chevron_right, color: colors.onSurface),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(AppColors colors) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.md,
      child: SwitchListTile(
        title: Text(
          'Dark Mode',
          style: context.text.titleMedium?.copyWith(
            color: colors.onSurface,
            fontSize: 16,
          ),
        ),
        secondary: Icon(
          ThemeController.instance.isDarkMode
              ? CupertinoIcons.moon_fill
              : CupertinoIcons.sun_max_fill,
          color: colors.onSurface,
        ),
        value: ThemeController.instance.isDarkMode,
        activeThumbColor: colors.positive,
        onChanged: (bool value) {
          AppHaptics.selection();
          ThemeController.instance.setDarkMode(value);
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false, bool isEmail = false}) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      decoration: AppInputs.filled(
        context,
        label: label,
        suffixIcon: IconButton(
          icon: Icon(CupertinoIcons.pencil, color: colors.onSurface),
          onPressed: () {
            // handle edit
          },
        ),
      ),
      style: context.text.bodyLarge?.copyWith(color: colors.onSurface),
      keyboardType: isNumeric
          ? TextInputType.number
          : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (isNumeric && int.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (isEmail &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _gradeController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
