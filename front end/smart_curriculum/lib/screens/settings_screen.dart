import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildSettingsOption(
              context,
              AppStrings.configureFaceRecognition,
              Icons.face,
            ),
            const SizedBox(height: 16),
            _buildSettingsOption(
              context,
              AppStrings.configureBluetooth,
              Icons.bluetooth,
            ),
            const SizedBox(height: 16),
            _buildSettingsOption(
              context,
              AppStrings.configureDeviceBinding,
              Icons.devices,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context, String title, IconData icon) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle settings option tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title clicked'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}