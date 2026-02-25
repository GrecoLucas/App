class ListInvitation {
  final String id;
  final String listId;
  final String listName;
  final String inviterUsername;
  final String invitedUsername;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  ListInvitation({
    required this.id,
    required this.listId,
    required this.listName,
    required this.inviterUsername,
    required this.invitedUsername,
    required this.createdAt,
    required this.status,
  });

  factory ListInvitation.fromJson(Map<String, dynamic> json) {
    return ListInvitation(
      id: json['id'].toString(),
      listId: json['list_id'].toString(),
      listName: json['list_name'] ?? '',
      inviterUsername: json['inviter_username'] ?? '',
      invitedUsername: json['invited_username'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'list_name': listName,
      'inviter_username': inviterUsername,
      'invited_username': invitedUsername,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  ListInvitation copyWith({
    String? id,
    String? listId,
    String? listName,
    String? inviterUsername,
    String? invitedUsername,
    DateTime? createdAt,
    String? status,
  }) {
    return ListInvitation(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      listName: listName ?? this.listName,
      inviterUsername: inviterUsername ?? this.inviterUsername,
      invitedUsername: invitedUsername ?? this.invitedUsername,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Agora mesmo';
    }
  }

  String get formattedDateTime {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} às ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
