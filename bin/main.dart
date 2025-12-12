import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/models.dart';

List<User> users = [];
List<Report> reports = [];
int reportIdCounter = 1;

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

void main() async {
  final router = Router();

  // Basic route
  router.get('/', (Request request) {
    return Response.ok('Hello from API Reportes!');
  });

  // Register user
  router.post('/register', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final username = data['username'];
    final email = data['email'];
    final password = data['password'];

    if (username == null || email == null || password == null) {
      return Response(400, body: 'Missing fields');
    }

    // Check if user exists
    if (users.any((u) => u.username == username || u.email == email)) {
      return Response(409, body: 'User already exists');
    }

    final hashed = hashPassword(password);
    final user = User(username, email, hashed);
    users.add(user);

    return Response.ok(jsonEncode({'message': 'User registered'}));
  });

  // Login
  router.post('/login', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final username = data['username'];
    final password = data['password'];

    final matchingUsers = users.where((u) => u.username == username);
    if (matchingUsers.isEmpty) {
      return Response(401, body: 'Invalid credentials');
    }
    final user = matchingUsers.first;
    if (user.passwordHash != hashPassword(password)) {
      return Response(401, body: 'Invalid credentials');
    }

    return Response.ok(jsonEncode({'message': 'Login successful'}));
  });

  // Create report
  router.post('/reports', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final title = data['title'];
    final description = data['description'];
    final author = data['author'];

    if (title == null || description == null || author == null) {
      return Response(400, body: 'Missing fields');
    }

    final report = Report(reportIdCounter.toString(), title, description, author, DateTime.now());
    reports.add(report);
    reportIdCounter++;

    return Response.ok(jsonEncode({'message': 'Report created', 'id': report.id}));
  });

  // Get feed
  router.get('/feed', (Request request) {
    final feed = reports.map((r) => r.toJson()).toList();
    return Response.ok(jsonEncode(feed));
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await shelf_io.serve(handler, 'localhost', 8080);
  print('Server listening on port ${server.port}');
}