import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final bool isDone;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String creatorId;
  final String? assignedToId;
  final List<String> imageUrls;
  final int color; // ARGB integer

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.isDone,
    required this.isFavorite,
    required this.tags,
    required this.createdAt,
    this.dueDate,
    required this.creatorId,
    this.assignedToId,
    required this.imageUrls,
    this.color = 0xFFFFFFFF, // Default white
  });

  factory Note.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      isDone: data['isDone'] ?? false,
      isFavorite: data['isFavorite'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      creatorId: data['creatorId'] ?? '',
      assignedToId: data['assignedToId'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      color: (data['color'] is int) ? data['color'] : 0xFFFFFFFF,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'isDone': isDone,
      'isFavorite': isFavorite,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'creatorId': creatorId,
      'assignedToId': assignedToId,
      'imageUrls': imageUrls,
      'color': color,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? isDone,
    bool? isFavorite,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? dueDate,
    String? creatorId,
    String? assignedToId,
    List<String>? imageUrls,
    int? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isDone: isDone ?? this.isDone,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      creatorId: creatorId ?? this.creatorId,
      assignedToId: assignedToId ?? this.assignedToId,
      imageUrls: imageUrls ?? this.imageUrls,
      color: color ?? this.color,
    );
  }
}
