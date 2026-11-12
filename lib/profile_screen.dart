import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'local_storage_repository.dart';
import 'chat_bloc.dart';
import 'chat_state.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileSaved;

  const ProfileScreen({super.key, this.onProfileSaved});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final LocalStorageRepository _storageRepo = LocalStorageRepository();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    setState(() {
      _nameController.text = _storageRepo.getUserName();
      _imagePath = _storageRepo.getUserAvatar();
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    final nameText = _nameController.text.trim();
    if (nameText.isEmpty) return;

    await _storageRepo.saveUserProfile(
      name: nameText,
      imagePath: _imagePath,
    );

    widget.onProfileSaved?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF141C24),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF00FF66), size: 18),
              SizedBox(width: 10),
              Text(
                'Operator Callsign & Avatar Updated',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: const Color(0xFF00FF66).withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayCallsign = _nameController.text.trim().isEmpty
        ? 'UNKNOWN_NODE'
        : _nameController.text.trim().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, chatState) {
          final int totalMessages = chatState.messages.length;
          final int sentByMe =
              chatState.messages.where((m) => m.isMe).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16222F), Color(0xFF141C24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF66)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF00FF66)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 12,
                                  color: Color(0xFF00FF66),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'NODE VERIFIED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF00FF66),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'ID #${displayCallsign.hashCode.abs().toString().substring(0, 4)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00E5FF),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: const Color(0xFF1E2A38),
                                backgroundImage: _imagePath != null
                                    ? FileImage(File(_imagePath!))
                                    : null,
                                child: _imagePath == null
                                    ? const Icon(
                                  Icons.person_outline_rounded,
                                  size: 48,
                                  color: Color(0xFF00E5FF),
                                )
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF141C24),
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Color(0xFF0B0F14),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Text(
                        displayCallsign,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap avatar to update node photo',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'MESH CALLSIGN CONFIGURATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Broadcast Display Name',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          hintText: 'Enter node callsign...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFF0B0F14),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: Color(0xFF00E5FF),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF00E5FF),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: const Color(0xFF0B0F14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save_rounded, size: 20),
                          label: const Text(
                            'SAVE NODE IDENTITY',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'NODE SPECIFICATIONS & LOGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _buildSpecRow(
                        icon: Icons.enhanced_encryption_outlined,
                        label: 'Payload Encryption',
                        value: 'AES-256 Enabled',
                        valueColor: const Color(0xFF00FF66),
                      ),
                      const Divider(color: Colors.white10, height: 22),
                      _buildSpecRow(
                        icon: Icons.storage_rounded,
                        label: 'Local Persistence',
                        value: 'Hive Encrypted Box',
                        valueColor: const Color(0xFF00E5FF),
                      ),
                      const Divider(color: Colors.white10, height: 22),
                      _buildSpecRow(
                        icon: Icons.history_rounded,
                        label: 'Transmissions Logged',
                        value: '$sentByMe sent / $totalMessages total',
                        valueColor: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[300]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}