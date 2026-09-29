import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient extends ChangeNotifier {
  // Uses local host on web, and PC's Wi-Fi IP on mobile devices for wireless connectivity
  static String get hostServerUrl {
    const configured = String.fromEnvironment('BACKEND_URL');
    if (configured.isNotEmpty) {
      final uri=Uri.parse(configured);
      if (!kDebugMode && uri.scheme != 'https') throw StateError('Release BACKEND_URL must use HTTPS.');
      return configured.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      if (kDebugMode) return 'http://127.0.0.1:8000';
      if (Uri.base.scheme != 'https') throw StateError('Release website must be served over HTTPS.');
      return Uri.base.origin;
    }
    if (kDebugMode) return 'http://10.0.2.2:8000';
    throw StateError('Configure an HTTPS BACKEND_URL for a mobile release.');
  }

  static String get baseUrl => '$hostServerUrl/api';

  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$hostServerUrl$cleanPath';
  }
  
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? accessToken;
  String? refreshToken;
  String? currentUserEmail;
  List<String> currentRoles = [];
  bool professionalVerified = false;
  int sessionVersion = 0;
  Future<bool>? _refreshing;
  late final http.Client _client = _CheckedClient(this);

  Future<bool> refreshSession() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  Future<bool> _refresh() async {
    final version = sessionVersion;
    final refresh = refreshToken;
    if (refresh == null) return false;
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/refresh/'), headers: {'Content-Type':'application/json'}, body: jsonEncode({'refresh':refresh})).timeout(const Duration(seconds:20));
      if (response.statusCode != 200 || version != sessionVersion) return false;
      final data = jsonDecode(response.body);
      accessToken = data['access'];
      refreshToken = data['refresh'] ?? refresh;
      return true;
    } catch (_) { return false; }
  }

  Future<Map<String,dynamic>> getData(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'), headers:headers);
    return Map<String,dynamic>.from(jsonDecode(response.body));
  }
  Future<void> deleteData(String path) async { await _client.delete(Uri.parse('$baseUrl$path'),headers:headers); }
  Future<List<Map<String,dynamic>>> getList(String path) async {
    final response = await _client.get(Uri.parse('$baseUrl$path'), headers:headers);
    return (jsonDecode(response.body) as List).map((e) => Map<String,dynamic>.from(e)).toList();
  }
  Future<Map<String,dynamic>> postData(String path, Map<String,dynamic> body) async {
    final response = await _client.post(Uri.parse('$baseUrl$path'), headers:headers, body:jsonEncode(body));
    return Map<String,dynamic>.from(jsonDecode(response.body));
  }
  Future<Map<String,dynamic>> patchData(String path, Map<String,dynamic> body) async {
    final response = await _client.patch(Uri.parse('$baseUrl$path'), headers:headers, body:jsonEncode(body));
    return Map<String,dynamic>.from(jsonDecode(response.body));
  }
  Future<String> documentUrl(String path) async {
    final response = await _client.get(Uri.parse(resolveUrl(path)), headers:headers);
    return jsonDecode(response.body)['url'] as String;
  }
  Future<Map<String,dynamic>> uploadDocument(String path, Map<String,String> fields, String name, List<int> bytes, {String field='file'}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (accessToken != null) request.headers['Authorization'] = 'Bearer $accessToken';
    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(field, bytes, filename:name));
    final response = await http.Response.fromStream(await _client.send(request));
    return Map<String,dynamic>.from(jsonDecode(response.body));
  }


  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  // ── Auth & OTP ──
  Future<Map<String, dynamic>> requestOtp({
    required String email,
    required String role,
    String mode = 'login',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/request-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'role': role, 'mode': mode}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? data['message'] ?? 'Failed to send OTP');
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String role,
    String? fullName,
    String? phoneNumber,
    List<String>? roles,
    Map<String, dynamic>? doctorProfile,
    Map<String, dynamic>? labProfile,
    Map<String, dynamic>? hospitalProfile,
    Map<String, dynamic>? orgProfile,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'otp': otp,
      'role': role,
    };
    if (fullName != null && fullName.isNotEmpty) {
      payload['full_name'] = fullName;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      payload['phone_number'] = phoneNumber;
    }
    if (roles != null && roles.isNotEmpty) {
      payload['roles'] = roles;
    }
    if (doctorProfile != null) {
      payload['doctor_profile'] = doctorProfile;
    }
    if (labProfile != null) {
      payload['lab_profile'] = labProfile;
    }
    if (hospitalProfile != null) {
      payload['hospital_profile'] = hospitalProfile;
    }
    if (orgProfile != null) {
      payload['org_profile'] = orgProfile;
    }
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      payload['date_of_birth'] = dateOfBirth;
    }
    if (gender != null && gender.isNotEmpty) {
      payload['gender'] = gender;
    }
    if (bloodGroup != null && bloodGroup.isNotEmpty) {
      payload['blood_group'] = bloodGroup;
    }
    if (allergies != null && allergies.isNotEmpty) {
      payload['allergies'] = allergies;
    }
    if (medicalConditions != null && medicalConditions.isNotEmpty) {
      payload['medical_conditions'] = medicalConditions;
    }
    if (currentMedications != null && currentMedications.isNotEmpty) {
      payload['current_medications'] = currentMedications;
    }
    if (emergencyContactName != null && emergencyContactName.isNotEmpty) {
      payload['emergency_contact_name'] = emergencyContactName;
    }
    if (emergencyContactPhone != null && emergencyContactPhone.isNotEmpty) {
      payload['emergency_contact_phone'] = emergencyContactPhone;
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['tokens'] != null) {
        accessToken = data['tokens']['access'];
        refreshToken = data['tokens']['refresh'];
        currentRoles = List<String>.from(data['user']['roles'] ?? ['patient']);
        professionalVerified = data['user']['professional_verified'] == true;
        sessionVersion++;
        notifyListeners();
      }
      return data;
    }
    throw Exception(data['error'] ?? data['message'] ?? 'Failed to verify OTP');
  }

  Future<Map<String, dynamic>> registerProfile(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register-profile/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Profile registration failed');
  }

  // ── Medical Records & Reports ──
  Future<List<dynamic>> getRecords() async {
    final response = await _client.get(Uri.parse('$baseUrl/reports/records/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createRecord(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reports/records/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getLabReports() async {
    final response = await _client.get(Uri.parse('$baseUrl/reports/lab-reports/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createLabReport(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reports/lab-reports/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getTimeline() async {
    final response = await _client.get(Uri.parse('$baseUrl/reports/timeline/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['timeline'] is List) return data['timeline'];
    }
    return [];
  }

  // ── Patients & Vitals ──
  Future<List<dynamic>> getFamilyMembers() async {
    final response = await _client.get(Uri.parse('$baseUrl/patients/family/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createFamilyMember(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/patients/family/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<bool> deleteFamilyMember(String memberId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/patients/family/$memberId/'),
      headers: headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<List<dynamic>> getVitals() async {
    final response = await _client.get(Uri.parse('$baseUrl/patients/vitals/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createVital(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/patients/vitals/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getEmergencyCard() async {
    final response = await _client.get(Uri.parse('$baseUrl/patients/me/'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {};
  }

  Future<Map<String, dynamic>> updateEmergencyCard(Map<String, dynamic> payload) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/patients/me/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  // ── Doctor Portal ──
  Future<List<dynamic>> getAppointments({String context = 'patient'}) async {
    final response = await _client.get(Uri.parse('$baseUrl/doctor/appointments/?context=$context'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/doctor/appointments/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> searchPatients(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    final response = await _client.get(
      Uri.parse('$baseUrl/doctor/patients/?q=${Uri.encodeComponent(cleanQuery)}&email=${Uri.encodeComponent(cleanQuery)}'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> registerDoctorPatient(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/doctor/patients/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/doctor/prescriptions/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getDoctorPatientChart(String patientId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/doctor/patients/$patientId/chart/'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<List<dynamic>> getDoctorDirectory([String query = '']) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    final url = '$baseUrl/doctor/directory/?q=${Uri.encodeComponent(cleanQuery)}&email=${Uri.encodeComponent(cleanQuery)}';
    final response = await _client.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }
    return [];
  }

  // ── Lab Portal ──
  Future<List<dynamic>> getLabOrders() async {
    final response = await _client.get(Uri.parse('$baseUrl/lab/orders/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createLabOrder(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/lab/orders/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> publishLabReport(String orderId, Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/lab/orders/$orderId/publish/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getLabPatients([String? query]) async {
    final qStr = (query != null && query.trim().isNotEmpty) ? '?q=${Uri.encodeComponent(query.trim())}' : '';
    final response = await _client.get(Uri.parse('$baseUrl/lab/patients/$qStr'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }
    return [];
  }

  Future<Map<String, dynamic>> uploadDirectLabReport({
    required String patientIdentifier,
    String? patientName,
    required String testName,
    required String category,
    String? summary,
    String? doctorName,
    String? fileName,
    List<int>? fileBytes,
    List<Map<String, dynamic>>? parameters,
  }) async {
    if (fileBytes != null && fileBytes.isNotEmpty && fileName != null) {
      final uri = Uri.parse('$baseUrl/lab/upload-report/');
      final request = http.MultipartRequest('POST', uri);
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
      request.fields['patient_identifier'] = patientIdentifier;
      if (patientName != null) request.fields['patient_name'] = patientName;
      request.fields['test_name'] = testName;
      request.fields['category'] = category;
      if (summary != null) request.fields['summary'] = summary;
      if (doctorName != null) request.fields['doctor_name'] = doctorName;
      if (parameters != null && parameters.isNotEmpty) {
        request.fields['parameters'] = jsonEncode(parameters);
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final streamed = await _client.send(request);
      final resp = await http.Response.fromStream(streamed);
      final data = jsonDecode(resp.body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'success': true};
      }
      throw Exception(data['error'] ?? 'Upload failed (${resp.statusCode})');
    } else {
      final response = await _client.post(
        Uri.parse('$baseUrl/lab/upload-report/'),
        headers: headers,
        body: jsonEncode({
          'patient_identifier': patientIdentifier,
          'patient_name': patientName ?? '',
          'test_name': testName,
          'category': category,
          'summary': summary ?? '',
          'doctor_name': doctorName ?? '',
          if (parameters != null && parameters.isNotEmpty) 'parameters': parameters,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'success': true};
      }
      throw Exception(data['error'] ?? 'Upload failed (${response.statusCode})');
    }
  }

  // ── Hospital Portal ──
  Future<List<dynamic>> getAdmissions() async {
    final response = await _client.get(Uri.parse('$baseUrl/hospital/admissions/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> admitPatient(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/hospital/admissions/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> dischargePatient(String admissionId, Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/hospital/admissions/$admissionId/discharge/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> uploadLabBatchCsv({required String csvText}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/lab/batch-upload/'),
      headers: headers,
      body: jsonEncode({'csv_text': csvText}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Batch upload failed');
  }

  // ── Consent Flow ──
  Future<Map<String, dynamic>> requestDoctorConsent({required String patientId, String? purpose}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/doctor/consent/request/'),
      headers: headers,
      body: jsonEncode({
        'patient_id': patientId,
        'purpose': purpose ?? 'Clinical Consultation & Medical History Review',
      }),
    );
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data is Map<String, dynamic> ? data : {'success': true};
      }
      throw Exception(data['error'] ?? data['message'] ?? 'Failed to request consent (${response.statusCode})');
    } catch (e) {
      if (e is Exception && !e.toString().contains('FormatException')) rethrow;
      throw Exception('Server returned error (${response.statusCode})');
    }
  }

  Future<List<dynamic>> getPatientConsents() async {
    final response = await _client.get(Uri.parse('$baseUrl/patients/consents/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> actionPatientConsent({required String consentId, required String action}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/patients/consents/$consentId/action/'),
      headers: headers,
      body: jsonEncode({'action': action}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> linkDoctorDirectly({String? doctorEmail, String? doctorId}) async {
    final payload = <String, dynamic>{};
    if (doctorEmail != null) payload['doctor_email'] = doctorEmail;
    if (doctorId != null) payload['doctor_id'] = doctorId;

    final response = await _client.post(
      Uri.parse('$baseUrl/patients/consents/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {'success': true};
    }
  }

  // ── Global Search ──
  Future<Map<String, dynamic>> searchGlobal(String query) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/search/?q=${Uri.encodeComponent(query)}'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'total_results': 0, 'prescriptions': [], 'lab_reports': [], 'doctors': []};
  }

  // ── Doctor Incoming Patient Requests ──
  Future<List<dynamic>> getDoctorIncomingRequests() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/doctor/incoming-requests/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['results'] is List) return data['results'];
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> actionDoctorIncomingRequest({
    required String consentId,
    required String action,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/doctor/incoming-requests/$consentId/action/'),
      headers: headers,
      body: jsonEncode({'action': action}),
    );
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {'success': response.statusCode == 200};
    }
  }

  // ── Admin Portal ──
  Future<Map<String, dynamic>> getAdminOverview() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin-portal/overview/'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': false, 'stats': {}, 'engine_status': {}, 'recent_activity': []};
  }

  Future<List<dynamic>> getAdminUsers({String? role, String? query}) async {
    final params = <String, String>{};
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') {
      params['role'] = role;
    }
    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }
    final uri = Uri.parse('$baseUrl/admin-portal/users/').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['users'] is List) return data['users'];
    }
    return [];
  }

  Future<Map<String, dynamic>> toggleUserVerification(String userId, {required bool verified, required String reason}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/admin-portal/users/$userId/toggle-verify/'),
      headers: headers,
      body:jsonEncode({'verified':verified, 'reason':reason}),
    );
    return jsonDecode(response.body);
  }

  void logout() {
    final oldAccess = accessToken;
    final oldRefresh = refreshToken;
    if (oldAccess != null && oldRefresh != null) {
      http.post(Uri.parse('$baseUrl/auth/logout/'), headers:{'Content-Type':'application/json','Authorization':'Bearer $oldAccess'}, body:jsonEncode({'refresh':oldRefresh})).timeout(const Duration(seconds:10)).catchError((_) => http.Response('', 503));
    }
    sessionVersion++;
    currentRoles = [];
    professionalVerified = false;
    accessToken = null;
    refreshToken = null;
    currentUserEmail = null;
    notifyListeners();
  }
}


class _CheckedClient extends http.BaseClient {
  final ApiClient owner;
  final http.Client transport = http.Client();
  _CheckedClient(this.owner);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest original) async {
    final version = owner.sessionVersion;
    final authenticated = original.headers.containsKey('Authorization');
    final bytes = await original.finalize().toBytes();
    Future<http.StreamedResponse> transmit() {
      final request = http.Request(original.method, original.url)..headers.addAll(original.headers)..bodyBytes = bytes;
      if (authenticated && owner.accessToken != null) request.headers['Authorization'] = 'Bearer ${owner.accessToken}';
      return transport.send(request).timeout(const Duration(seconds:30));
    }
    var response = await transmit();
    if (response.statusCode == 401 && authenticated) {
      await response.stream.drain<void>();
      if (await owner.refreshSession()) {
        response = await transmit();
      } else {
        if (version == owner.sessionVersion) owner.logout();
        throw Exception('Your session expired. Please sign in again.');
      }
    }
    if (authenticated && version != owner.sessionVersion) {
      await response.stream.drain<void>();
      throw Exception('Session changed; stale response discarded.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      String message = 'Request failed (${response.statusCode}).';
      try { final data=jsonDecode(body); message=(data is Map ? data['error'] ?? data['detail'] ?? data : data).toString(); } catch (_) {}
      throw Exception(message);
    }
    return response;
  }
}
