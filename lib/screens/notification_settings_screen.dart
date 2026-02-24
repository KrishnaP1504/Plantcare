import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _watering = true;
  bool _fertilizing = true;
  bool _misting = false;
  bool _tempAlerts = true;
  bool _stormAlerts = true;
  bool _weeklyTips = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('notificationSettings')) {
        final data = doc.data()!['notificationSettings'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _watering = data['watering'] ?? true;
            _fertilizing = data['fertilizing'] ?? true;
            _misting = data['misting'] ?? false;
            _tempAlerts = data['tempAlerts'] ?? true;
            _stormAlerts = data['stormAlerts'] ?? true;
            _weeklyTips = data['weeklyTips'] ?? true;
            // Parse reminder time safely to avoid NumberFormatException when stored value is malformed
            final rawTime = (data['reminderTime'] ?? "9:00") as String;
            final timeParts = rawTime.split(':');
            int hour = 9;
            int minute = 0;
            if (timeParts.length >= 2) {
              hour = int.tryParse(timeParts[0]) ?? 9;
              minute = int.tryParse(timeParts[1]) ?? 0;
            }
            _reminderTime = TimeOfDay(hour: hour, minute: minute);
          });
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'notificationSettings': {
          'watering': _watering,
          'fertilizing': _fertilizing,
          'misting': _misting,
          'tempAlerts': _tempAlerts,
          'stormAlerts': _stormAlerts,
          'weeklyTips': _weeklyTips,
          'reminderTime': '${_reminderTime.hour.toString()}:${_reminderTime.minute.toString().padLeft(2, '0')}',
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings Saved")));
    }
  }

  Future<void> _pickTime() async {
    final newTime = await showTimePicker(context: context, initialTime: _reminderTime);
    if (newTime != null) {
      setState(() => _reminderTime = newTime);
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notifications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.clock, color: AppTheme.primary),
                          SizedBox(width: 12),
                          Text("Daily Reminder", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                          child: Text(_reminderTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text("Care Schedule", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildToggle("Watering", _watering, (v) { setState(() => _watering = v); _saveSettings(); }),
                _buildToggle("Fertilizing", _fertilizing, (v) { setState(() => _fertilizing = v); _saveSettings(); }),
                _buildToggle("Misting", _misting, (v) { setState(() => _misting = v); _saveSettings(); }),

                const SizedBox(height: 24),
                const Text("Conditions & Weather", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildToggle("Temperature Alerts", _tempAlerts, (v) { setState(() => _tempAlerts = v); _saveSettings(); }),
                _buildToggle("Storm & Frost", _stormAlerts, (v) { setState(() => _stormAlerts = v); _saveSettings(); }),

                const SizedBox(height: 24),
                const Text("General", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildToggle("Weekly Tips", _weeklyTips, (v) { setState(() => _weeklyTips = v); _saveSettings(); }),
              ],
            ),
          ),
    );
  }

  Widget _buildToggle(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Switch.adaptive(
            value: value, 
            onChanged: onChanged,
            // FIX: Replaced activeColor (deprecated) with activeThumbColor
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.2),
          )
        ],
      ),
    );
  }
}