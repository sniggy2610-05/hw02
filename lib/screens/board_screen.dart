import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/board_service.dart';

class BoardScreen extends StatefulWidget {
  final User user;
  final String displayName;
  const BoardScreen({super.key, required this.user, required this.displayName});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _board = BoardService();
  final _controller = TextEditingController();
  late final Stream<List<Message>> _stream = _board.messageBoard();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _errorText(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Not allowed: you can only change your own messages.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (_posting || text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await _board.postMessage(
        authorUid: widget.user.uid,
        authorName: widget.displayName,
        text: text,
      );
      _controller.clear();
    } catch (e) {
      if (mounted) _snack(_errorText(e));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _edit(Message m) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditDialog(initialText: m.text),
    );
    if (newText == null || newText.isEmpty || newText == m.text) return;
    try {
      await _board.editMessage(messageId: m.id, newText: newText);
    } catch (e) {
      if (mounted) _snack(_errorText(e));
    }
  }

  Future<void> _delete(Message m) async {
    try {
      await _board.deleteMessage(messageId: m.id);
    } catch (e) {
      if (mounted) _snack(_errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Could not load the board. Try again later.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data!;
                if (msgs.isEmpty) {
                  return const Center(
                      child: Text('No messages yet. Be the first to post!'));
                }
                return ListView.builder(
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.authorUid == widget.user.uid;
                    final when = m.createdAt == null
                        ? 'Sending...'
                        : m.createdAt!.toLocal().toString().substring(0, 16);
                    return ListTile(
                      key: ValueKey(m.id),
                      title: Text(m.text),
                      subtitle: Text(
                          '${m.authorName} · $when${m.editedAt != null ? ' · edited' : ''}'),
                      trailing: mine
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _edit(m)),
                                IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _delete(m)),
                              ],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration:
                          const InputDecoration(hintText: 'Write a message'),
                      onSubmitted: (_) => _post(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _posting ? null : _post,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final String initialText;
  const _EditDialog({required this.initialText});
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit message'),
      content: TextField(controller: _c, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
