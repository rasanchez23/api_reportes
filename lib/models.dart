import 'dart:convert';

class User {
  final String username;
  final String email;
  final String passwordHash;

  User(this.username, this.email, this.passwordHash);

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
  };
}

class Report {
  final String id;
  final String title;
  final String description;
  final String author;
  final DateTime timestamp;

  Report(this.id, this.title, this.description, this.author, this.timestamp);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'author': author,
    'timestamp': timestamp.toIso8601String(),
  };
}