import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? accessToken;
  String? refreshToken;
  String? currentUserEmail;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        if (currentUserEmail != null && currentUserEmail!.isNotEmpty) 'X-User-Email': currentUserEmail!,
      };

  // ── Auth & OTP ──
  Future<Map<String, dynamic>> requestOtp({
    required String email,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/request-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'role': role}),
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
    Map<String, dynamic>? orgProfile,
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
    if (orgProfile != null) {
      payload['org_profile'] = orgProfile;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['tokens'] != null) {
        accessToken = data['tokens']['access'];
        refreshToken = data['tokens']['refresh'];
      }
      return data;
    }
    throw Exception(data['error'] ?? data['message'] ?? 'Failed to verify OTP');
  }

  Future<Map<String, dynamic>> registerProfile(Map<String, dynamic> payload) async {
    final response = await http.post(
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
    final response = await http.get(Uri.parse('$baseUrl/reports/records/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createRecord(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/records/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getLabReports() async {
    final response = await http.get(Uri.parse('$baseUrl/reports/lab-reports/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createLabReport(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/lab-reports/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getTimeline() async {
    final response = await http.get(Uri.parse('$baseUrl/reports/timeline/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['timeline'] is List) return data['timeline'];
    }
    return [];
  }

  // ── Patients & Vitals ──
  Future<List<dynamic>> getFamilyMembers() async {
    final response = await http.get(Uri.parse('$baseUrl/patients/family/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createFamilyMember(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/family/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<bool> deleteFamilyMember(String memberId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/patients/family/$memberId/'),
      headers: headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<List<dynamic>> getVitals() async {
    final response = await http.get(Uri.parse('$baseUrl/patients/vitals/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createVital(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/vitals/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getEmergencyCard() async {
    final response = await http.get(Uri.parse('$baseUrl/patients/emergency-card/'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {};
  }

  Future<Map<String, dynamic>> updateEmergencyCard(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patients/emergency-card/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  // ── Doctor Portal ──
  Future<List<dynamic>> getAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/doctor/appointments/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctor/appointments/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> searchPatients(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    final response = await http.get(
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
    final response = await http.post(
      Uri.parse('$baseUrl/doctor/patients/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctor/prescriptions/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getDoctorPatientChart(String patientId) async {
    final response = await http.get(
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
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
    }
    return [];
  }

  // ── Lab Portal ──
  Future<List<dynamic>> getLabOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/lab/orders/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createLabOrder(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lab/orders/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> publishLabReport(String orderId, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lab/orders/$orderId/publish/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  // ── Hospital Portal ──
  Future<List<dynamic>> getAdmissions() async {
    final response = await http.get(Uri.parse('$baseUrl/hospital/admissions/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> admitPatient(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/hospital/admissions/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> dischargePatient(String admissionId, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/hospital/admissions/$admissionId/discharge/'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> uploadLabBatchCsv({required String csvText}) async {
    final response = await http.post(
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
    final response = await http.post(
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
    final response = await http.get(Uri.parse('$baseUrl/patients/consents/'), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['results'] is List) return data['results'];
    }
    return [];
  }

  Future<Map<String, dynamic>> actionPatientConsent({required String consentId, required String action}) async {
    final response = await http.post(
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

    final response = await http.post(
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
    final response = await http.get(
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
      final response = await http.get(
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
    final response = await http.post(
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

  void logout() {
    accessToken = null;
    refreshToken = null;
    currentUserEmail = null;
  }
}
