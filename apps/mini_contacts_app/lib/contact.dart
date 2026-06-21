class Contact {
  Contact({
    this.id,
    required this.studentId,
    required this.name,
    required this.phone,
    required this.avatar,
  });

  final int? id;
  final String studentId;
  final String name;
  final String phone;
  final String avatar;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      studentId: json['studentId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] as String,
    );
  }

  factory Contact.fromMap(Map<String, Object?> map) {
    return Contact(
      id: map['id'] as int?,
      studentId: map['studentId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      avatar: map['avatar'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'studentId': studentId,
      'name': name,
      'phone': phone,
      'avatar': avatar,
    };
  }

  Contact copyWith({
    int? id,
    String? studentId,
    String? name,
    String? phone,
    String? avatar,
  }) {
    return Contact(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
    );
  }
}
