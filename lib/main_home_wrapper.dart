import 'dart:io';
import 'package:flutter/material.dart';
import 'mesh_chat_tab.dart';
import 'discovery_tab.dart';
import 'profile_screen.dart';
import 'local_storage_repository.dart';

class MainHomeWrapper extends StatefulWidget {
  const MainHomeWrapper({super.key});

  @override
  State<MainHomeWrapper> createState() => _MainHomeWrapperState();
}

class _MainHomeWrapperState extends State<MainHomeWrapper> {
  int _currentIndex = 0;
  final LocalStorageRepository _storageRepo = LocalStorageRepository();
  String _userName = '';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    setState(() {
      _userName = _storageRepo.getUserName();
      _avatarPath = _storageRepo.getUserAvatar();
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Mesh Group Chat';
      case 1:
        return 'Radar & Peers';
      case 2:
        return 'My Profile';
      default:
        return 'Blue Mesh';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const MeshChatTab(),
      const DiscoveryTab(),
      ProfileScreen(
        onProfileSaved: _loadUserProfile,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple.shade700,
                backgroundImage:
                _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                child: _avatarPath == null
                    ? Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadUserProfile();
        },
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Group Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radar_outlined),
            activeIcon: Icon(Icons.radar),
            label: 'Radar & Peers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}