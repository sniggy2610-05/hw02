import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'board_screen.dart';
import 'register_screen.dart' show kRoles;

class ProfileGate extends StatefulWidget {
  final User user;
  const ProfileGate({super.key, required this.user});
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final _users = UserService();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream =
  _users.userRecord(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your profile.'),
                  TextButton(
                      onPressed: () => AuthService().signOut(),
                      child: const Text('Sign out')),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!.data();
        if (!UserService.isComplete(data)) {
          return _CompleteProfile(user: widget.user, users: _users);
        }
        return BoardScreen(
          user: widget.user,
          displayName: '${data!['firstName']} ${data['lastName']}',
        );
      },
    );
  }
}

class _CompleteProfile extends StatefulWidget {
  final User user;
  final UserService users;
  const _CompleteProfile({required this.user, required this.users});
  @override
  State<_CompleteProfile> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<_CompleteProfile> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  String _role = kRoles.first;
  bool _busy = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _first.text.trim().isEmpty || _last.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.users.saveUserRecord(widget.user,
          firstName: _first.text, lastName: _last.text, role: _role);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile not saved. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile'), actions: [
        TextButton(
            onPressed: () => AuthService().signOut(),
            child: const Text('Sign out')),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
                controller: _first,
                decoration: const InputDecoration(labelText: 'First name')),
            TextField(
                controller: _last,
                decoration: const InputDecoration(labelText: 'Last name')),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: kRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving...' : 'Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}