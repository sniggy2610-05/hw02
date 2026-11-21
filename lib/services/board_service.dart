import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String authorUid;
  final String authorName;
  final DateTime? createdAt; // null while the server timestamp is pending
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    this.editedAt,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Message(
      id: d.id,
      text: (m['text'] ?? '') as String,
      authorUid: (m['authorUid'] ?? '') as String,
      authorName: (m['authorName'] ?? 'Unknown') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      editedAt: (m['editedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BoardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// CREATE
  String newId() => _db.collection('messages').doc().id;

  Future<void> postMessage({
    required String id,
    required String authorUid,
    required String authorName,
    required String text,
  }) {
    return _db.collection('messages').doc(id).set({
      'authorUid': authorUid,
      'authorName': authorName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// READ (live stream)
  Stream<List<Message>> messageBoard() {
    return _db
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(Message.fromDoc).toList());
  }

  /// UPDATE
  Future<void> editMessage(
      {required String messageId, required String newText}) {
    return _db.collection('messages').doc(messageId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// DELETE
  Future<void> deleteMessage({required String messageId}) {
    return _db.collection('messages').doc(messageId).delete();
  }
}