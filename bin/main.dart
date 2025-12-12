import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../lib/models.dart';

List<User> users = [];
List<Report> reports = [];
Map<String, List<String>> reportLikes = {}; // id reporte -> lista de usuarios que dieron like
Map<String, List<Map<String, dynamic>>> reportComments = {}; // id reporte -> lista de comentarios
int reportIdCounter = 1;

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

// Middleware para CORS
Response addCorsHeaders(Response response) {
  return response.change(headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
}

void main() async {
  final router = Router();

  // Basic route
  router.get('/', (Request request) {
    return addCorsHeaders(Response.ok('Hello from API Reportes!'));
  });

  // Handle OPTIONS requests for CORS
  router.options('/<ignored|.*>', (Request request) {
    return addCorsHeaders(Response.ok(''));
  });

  // Register user
  router.post('/register', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final username = data['username'];
    final email = data['email'];
    final password = data['password'];

    if (username == null || email == null || password == null) {
      return addCorsHeaders(Response(400, body: jsonEncode({'error': 'Missing fields'})));
    }

    // Check if user exists
    if (users.any((u) => u.username == username || u.email == email)) {
      return addCorsHeaders(Response(409, body: jsonEncode({'error': 'User already exists'})));
    }

    final hashed = hashPassword(password);
    final user = User(username, email, hashed);
    users.add(user);

    return addCorsHeaders(Response.ok(jsonEncode({'message': 'User registered', 'username': username})));
  });

  // Login
  router.post('/login', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final username = data['username'];
    final password = data['password'];

    final matchingUsers = users.where((u) => u.username == username);
    if (matchingUsers.isEmpty) {
      return addCorsHeaders(Response(401, body: jsonEncode({'error': 'Invalid credentials'})));
    }
    final user = matchingUsers.first;
    if (user.passwordHash != hashPassword(password)) {
      return addCorsHeaders(Response(401, body: jsonEncode({'error': 'Invalid credentials'})));
    }

    return addCorsHeaders(Response.ok(jsonEncode({'message': 'Login successful', 'username': username})));
  });

  // Create report
  router.post('/reports', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final title = data['title'];
    final description = data['description'];
    final author = data['author'];

    if (title == null || description == null || author == null) {
      return addCorsHeaders(Response(400, body: jsonEncode({'error': 'Missing fields'})));
    }

    final report = Report(reportIdCounter.toString(), title, description, author, DateTime.now());
    reports.add(report);
    reportIdCounter++;

    return addCorsHeaders(Response.ok(jsonEncode({'message': 'Report created', 'id': report.id})));
  });

  // Get feed
  router.get('/feed', (Request request) {
    final feed = reports.map((r) {
      final reportData = r.toJson();
      reportData['likes'] = reportLikes[r.id]?.length ?? 0;
      reportData['comments'] = reportComments[r.id]?.length ?? 0;
      return reportData;
    }).toList();
    return addCorsHeaders(Response.ok(
      jsonEncode(feed),
      headers: {'Content-Type': 'application/json'},
    ));
  });

  // Get report details
  router.get('/reports/<reportId>', (Request request, String reportId) {
    final report = reports.firstWhere(
      (r) => r.id == reportId,
      orElse: () => Report('', '', '', '', DateTime.now()),
    );
    
    if (report.id.isEmpty) {
      return addCorsHeaders(Response(404, body: jsonEncode({'error': 'Report not found'})));
    }

    final reportData = report.toJson();
    reportData['likes'] = reportLikes[reportId]?.length ?? 0;
    reportData['comments'] = reportComments[reportId] ?? [];
    reportData['userLiked'] = false;
    
    return addCorsHeaders(Response.ok(
      jsonEncode(reportData),
      headers: {'Content-Type': 'application/json'},
    ));
  });

  // Like a report
  router.post('/reports/<reportId>/like', (Request request, String reportId) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final username = data['username'];

    final report = reports.firstWhere(
      (r) => r.id == reportId,
      orElse: () => Report('', '', '', '', DateTime.now()),
    );

    if (report.id.isEmpty) {
      return addCorsHeaders(Response(404, body: jsonEncode({'error': 'Report not found'})));
    }

    reportLikes.putIfAbsent(reportId, () => []);
    if (!reportLikes[reportId]!.contains(username)) {
      reportLikes[reportId]!.add(username);
    }

    return addCorsHeaders(Response.ok(jsonEncode({
      'message': 'Like added',
      'likes': reportLikes[reportId]!.length,
    })));
  });

  // Add comment to report
  router.post('/reports/<reportId>/comments', (Request request, String reportId) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final username = data['username'];
    final text = data['text'];

    final report = reports.firstWhere(
      (r) => r.id == reportId,
      orElse: () => Report('', '', '', '', DateTime.now()),
    );

    if (report.id.isEmpty) {
      return addCorsHeaders(Response(404, body: jsonEncode({'error': 'Report not found'})));
    }

    reportComments.putIfAbsent(reportId, () => []);
    reportComments[reportId]!.add({
      'username': username,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return addCorsHeaders(Response.ok(jsonEncode({
      'message': 'Comment added',
      'comments': reportComments[reportId]!.length,
    })));
  });

  // Get user profile
  router.get('/users/<username>', (Request request, String username) {
    final user = users.firstWhere(
      (u) => u.username == username,
      orElse: () => User('', '', ''),
    );

    if (user.username.isEmpty) {
      return addCorsHeaders(Response(404, body: jsonEncode({'error': 'User not found'})));
    }

    final userReports = reports.where((r) => r.author == username).length;

    return addCorsHeaders(Response.ok(jsonEncode({
      'username': user.username,
      'email': user.email,
      'reports': userReports,
    })));
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await shelf_io.serve(handler, '0.0.0.0', 8080);
  print('Server listening on port ${server.port}');
}